SELECT * FROM (
    -- [CTE 1] Isola os saldos apenas do depósito transitório (ex: 999) com saldo positivo.
    -- O objetivo é focar apenas nos materiais que ainda estão pendentes de desembaraço aduaneiro.
    WITH 
    cte_saldo_transitorio AS (
        SELECT id_empresa, id_item, versao, SUM(valor) AS valor_total
          FROM erp_schema.fato_estoque_saldos
         WHERE id_empresa = 1
           AND id_deposito = 999
           AND quantidade > 0
         GROUP BY id_empresa, id_item, versao
    ),

    -- [CTE 2] Prepara a base de volumes, recriando as regras de código de barras
    -- e calculando o saldo real do volume (quantidade original menos quantidade consumida).
    cte_base AS (
        SELECT vol.id_empresa,
               vol.id_sequencial,
               -- Só monta o código de barras se a tabela de itens já tiver sido povoada
               CASE 
                   WHEN volit.id_seq_volume IS NOT NULL 
                   THEN '-10-' || TO_CHAR(volit.id_seq_volume, 'fm00000000') || volit.id_seq_item 
                   ELSE NULL 
               END AS codigo_barra,
               vol.origem,
               vol.id_item,
               vol.versao,
               vol.data_registro,
               vol.usuario,
               vol.observacao,
               vol.id_deposito,
               vol.lote,
               vol.data_validade,
               volit.endereco,
               -- Se não estiver populado, o saldo temporário do volume é zero
               NVL(volit.quantidade - volit.quantidade_consumida, 0) AS saldo_volume
          FROM erp_schema.fato_estoque_volumes vol
         -- GARANTIA DO FILTRO: INNER JOIN com a lista de saldos para trazer apenas trânsito
         INNER JOIN cte_saldo_transitorio saldo 
            ON saldo.id_empresa = vol.id_empresa
           AND saldo.id_item = vol.id_item
           AND saldo.versao = vol.versao
         -- PREVENÇÃO DE PERDA: LEFT JOIN para não excluir volumes não populados
          LEFT JOIN erp_schema.fato_estoque_volumes_itens volit
            ON volit.id_empresa = vol.id_empresa
           AND volit.id_seq_volume = vol.id_sequencial
           AND volit.flag_consumido = 'N' 
         WHERE vol.id_empresa = 1
    ),

    -- [CTE 3] Captura a movimentação mais recente de cada código de barras 
    -- utilizando Window Function (ROW_NUMBER) para otimizar a performance.
    cte_mov_recente AS (
        SELECT m.id_empresa,
               m.codigo_barra,
               m.id_deposito,
               ROW_NUMBER() OVER (PARTITION BY m.id_empresa, m.codigo_barra ORDER BY m.origem DESC) AS rn
          FROM erp_schema.fato_movimentacao_codbarra m
         INNER JOIN cte_base b 
            ON b.id_empresa = m.id_empresa 
           AND b.codigo_barra = m.codigo_barra
         WHERE m.id_empresa = 1
           AND b.codigo_barra IS NOT NULL 
    ),

    -- [CTE 4] Define a localização atual do material.
    -- Se houve movimentação recente, assume o novo depósito; senão, mantém a base.
    cte_juncao AS (
        SELECT b.id_empresa,
               b.origem,
               b.id_item,
               b.versao,
               b.data_registro,
               b.observacao,
               b.saldo_volume,
               NVL(m.id_deposito, b.id_deposito) AS deposito_atual
          FROM cte_base b
          LEFT JOIN cte_mov_recente m
            ON m.id_empresa = b.id_empresa
           AND m.codigo_barra = b.codigo_barra
           AND m.rn = 1
    )

    -- [Consulta Principal] Cruza as Notas Fiscais de Importação com a posição de estoque e
    -- calcula o Ageing (dias) para classificar o status da documentação alfandegária.
    SELECT nf.id_empresa, 
           nf.numero_documento,
           forn.nome_fornecedor, 
           j.id_item,
           j.versao, 
           nfi.ordem_compra || ' - ' || nfi.item_compra AS id_ordem_compra,
           nf.data_entrada, 
           ROUND(SYSDATE - nf.data_entrada) AS dias_ageing,
           -- Regra de negócio: Classificação do Ageing no depósito transitório
           CASE 
               WHEN ROUND(SYSDATE - nf.data_entrada) < 2 THEN 'Normal'
               WHEN ROUND(SYSDATE - nf.data_entrada) BETWEEN 2.01 AND 4 THEN 'Atenção'
               ELSE 'Atrasado' 
           END AS status_desembaraco,
           MAX(nfi.id_lancamento) AS max_lancamento, 
           MAX(j.origem) AS max_origem, 
           NVL(SUM(j.saldo_volume), 0) AS total_saldo_volumes   
      FROM erp_schema.fato_notas_fiscais nf
     INNER JOIN erp_schema.fato_notas_fiscais_itens nfi
        ON nfi.id_empresa = nf.id_empresa
       AND nfi.id_seq_nota = nf.id_sequencia 
     INNER JOIN cte_juncao j
        ON j.id_empresa = nfi.id_empresa
       AND j.origem = nfi.id_empresa || 'MOVTO' || nfi.id_lancamento
       AND j.id_item = nfi.id_item
       AND j.versao = nfi.versao
       AND j.deposito_atual = 999 -- Filtro para o Depósito Transitório
       AND NVL(j.saldo_volume, 0) > 0
     INNER JOIN dw.dim_fornecedores forn
        ON forn.id_fornecedor = nf.id_fornecedor
     WHERE nf.id_empresa = 1
     GROUP BY nf.id_empresa, 
              nf.numero_documento, 
              nf.data_entrada, 
              j.id_item, 
              j.versao, 
              forn.nome_fornecedor,  
              nfi.ordem_compra || ' - ' || nfi.item_compra
     ORDER BY j.id_item
) consulta
-- Filtros dinâmicos que serão preenchidos pela ferramenta de BI
WHERE status_desembaraco IN (:filtro_status)
  AND id_empresa IN (:filtro_empresa);