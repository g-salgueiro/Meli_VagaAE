# Documentação do Projeto Meli Vaga AE

## 01. Módulo Analytics (`01_dashboard`)

**Documentação apartada.**

## 02. Módulo SQL (`02_sql`)

### Estrutura do Banco de Dados
- **`create_tables.sql`**: Define a modelagem dimensional com:
  **Tabelas principais:**
  - `Customer` (Clientes/vendedores com flag is_seller)
  - `Product` (Informações técnicas dos produtos)
  - `Post` (Anúncios vinculados a produtos e vendedores)
  - `Sale` (Transações de vendas com cálculos armazenados)

  **Tabelas adicionais não solicitadas:**
  - `ItemHistory` (Histórico de preços/status dos anúncios)
  - `PaymentMethod` (Métodos de pagamento dos clientes)
  - `FinancialTransaction` (Transações financeiras)
  - `Carrier` (Transportadoras parceiras)
  - `DeliveryTracking` (Rastreamento de entregas)

### Principais Decisões Implementadas:
1. Separação física entre `Product` (dados técnicos) e `Post` (contexto comercial)
2. Uso de DECIMAL(10,2) para valores monetários (preço, custo de frete)
3. Constraints de integridade referencial entre todas as tabelas relacionadas
4. Campos timestamp (created_at/updated_at) para auditoria em todas as entidades
5. Coluna gerada (sale_total) para cálculo automático do total da venda

## 03. Módulo API (`03_api`)

### Arquivos Principais:
- **`auth.py`**: Gerencia autenticação OAuth2 com tokens de acesso e refresh
- **`funcs.py`**: Contém as funções principais de coleta de dados da API
- **`main.py`**: Orquestra o pipeline de execução completo

### Mecanismos de Controle:
1. **Tratamento de Erros**:
   - Isolamento de falhas por item/termo
   - Logs estruturados com:
     - Timestamp
     - Tipo de erro
     - Contexto da operação

### Decisões de Projeto:
1. **Persistência de Dados**:
   - CSV para compatibilidade com BI
   - Checkpoints parciais para recuperação
2. **Separação de Conceitos**: 
    - Camada de autenticação (auth)
    - Lógica de negócio (funcs)
    - Orquestração (main)
3. **Logging**:    
    - Mensagens de erro em português
    - Logging detalhado por item/termo

### Análise Detalhada
1. **auth.py**
    - Propósito: gerenciamento de autenticação OAuth2 com Mercado Livre
    - Implementação:
        - Credenciais hardcoded para facilitar testes (não recomendado para produção)
        - Fluxo de refresh token implementado via POST
        - Token fixo (TOKEN) para uso imediato
    - Técnicas :
        - Uso de requests para chamadas HTTP

2. **funcs.py**
    - *Funções*:
        1. `tratar_erro_http(status_code: int) -> str`
            - Mapeia códigos HTTP para mensagens em PT-BR
            - Parâmetro: 
                - Código de status HTTP
            - Retorno: 
                - Mensagem contextualizada
        2. `buscar_itens(query: str, limit: int = 50) -> List[str]`
            - Parâmetros:
                - query: termo de busca
                - limit: quantidade máxima de resultados (padrão 50)
            - Retorno: 
                - Lista de IDs de itens
            - Tratamento de erros com raise_for_status()
        3. `obter_detalhes_item(item_id: str) -> Dict`
            - Parâmetro: 
                - ID do item
            - Retorno: 
                - Dicionário com metadados completos
            - Headers de autorização com token Bearer

    - *Técnicas*:
        - Type hints para melhor tipagem
        - Exceções customizadas com mensagens em português
        - Separação clara entre lógica de negócio e tratamento de erros

3. **main.py**
    - Fluxo principal:
        1. Define termos de busca e arquivo de saída temporal
        2. Loop de coleta com tratamento de erros por termo
        3. Consolidação em Dataframe `pandas`
        4. Exportação para CSV

    - **Paginação e Controle de Requisições**:
        - Mecanismo de 3 requisições por termo (offset 0, 50, 100), conforme limite da API
        - Parâmetros `limit=50` e `offset` para controle da API
        - Remoção de duplicados com `list(set())` após coleta
        - Respeito ao limite máximo da API (150 itens por termo)
        - Controle de erros por página com retentativas automáticas

    - Técnicas:
        - Uso de `pandas` para manipulação de dados
        - Nomeação dinâmica do arquivo de saída com timestamp
        - Estrutura modularizada com importação de funções
        - Controle de progresso via console

**Padrões de Qualidade**:
    - Mensagens de erro em português
    - Logging detalhado por item/termo
    - Separação entre:
        - Camada de autenticação (auth)
        - Lógica de negócio (funcs)
        - Orquestração (main)
    - Compatibilidade com BI via CSV


## Estrutura de Diretórios
```
├── 01_dashboard/
│   ├── data/    # Diretório com dados usados no dashboard
│   ├── Dashboard_GitHub.pbix    # Dashboard em PowerBI
├── 02_etl/
├── 02_sql/
│   ├── create_tables.sql    # DDL completo
│   ├── respuestas_negocio.sql  # Consultas analíticas
│   └── diagrama.md         # Documentação do schema
├── 03_api/
│   ├── auth.py             # Gestão de tokens
│   ├── funcs.py            # Funções principais
│   └── main.py             # Pipeline de execução
└── output/                 # Dados gerados
```