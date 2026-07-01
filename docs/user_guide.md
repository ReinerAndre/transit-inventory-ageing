# 📖 Guia do Usuário: Monitoramento de Desembaraço Aduaneiro

---

## 🎯 Visão Geral
Este relatório foi desenvolvido para dar total visibilidade aos materiais de importação que se encontram no **Depósito Transitório**. O objetivo principal é garantir que a equipe logística e de comércio exterior acompanhe o tempo de espera (*Ageing*) desde a emissão da Nota Fiscal até a aprovação da documentação de desembaraço aduaneiro, prevenindo atrasos operacionais e riscos de *compliance*.

## ⚙️ Regras de Negócio e Alertas (*Ageing*)
O sistema monitora automaticamente há quantos dias a Nota Fiscal de Importação foi registrada e classifica a criticidade do material aguardando documentação. As faixas de alerta são:

| Status Visual | Regra de Negócio (Dias de Espera) | Ação Recomendada |
| :--- | :--- | :--- |
| 🟢 **Normal** | Menos de 2 dias (0 a 1.99) | Fluxo padrão. Nenhuma ação imediata necessária. |
| 🟡 **Atenção** | Entre 2 e 4 dias | Acionar equipe de Comex/Despachante para prever liberação. |
| 🔴 **Atrasado** | Mais de 4 dias | Risco operacional. Prioridade máxima de resolução e cobrança. |

---

## 📊 Dicionário de Dados
Abaixo estão os principais indicadores e colunas que você encontrará neste relatório, traduzidos para o dia a dia da operação:

* **Documento (NF):** O número oficial da Nota Fiscal de Importação registrada no ERP.
* **Fornecedor:** Razão social do fornecedor internacional ou despachante responsável.
* **Item e Versão:** O código e a revisão do material que está em trânsito.
* **Ordem de Compra (OC):** O número do pedido original associado àquela importação, facilitando a rastreabilidade com o setor de Suprimentos.
* **Data de Entrada:** A data exata em que a Nota Fiscal foi registrada no sistema.
* **Dias de Trânsito (Ageing):** O tempo total (em dias corridos) desde o registro da nota até o momento atual.
* **Saldo de Volumes:** A quantidade física de itens atrelados àquela nota que ainda constam no depósito transitório e precisam de liberação.

---

## 🔍 Como Utilizar os Filtros
Para análises específicas, utilize os filtros localizados na barra superior (ou lateral) do painel:
* **Empresa / Filial:** Filtre os dados por CNPJ ou unidade de negócio específica.
* **Filtro de Status:** Selecione apenas "Atenção" ou "Atrasado" para priorizar as reuniões matinais de operação (*Daily Meetings*).

---

## ⏱️ Frequência de Atualização e Suporte (SLA)
* **Atualização dos Dados:** Este relatório reflete o banco de dados do ERP e sempre está atualizado.
* **Fonte da Informação:** Módulos de Suprimentos.
* **Reporte de Problemas:** Em caso de divergência de saldos, certifique-se primeiro de que o material não foi consumido ou movimentado fisicamente no ERP. Persistindo o erro, abra um chamado com a equipe de Dados/TI.
