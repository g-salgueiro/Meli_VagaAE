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
  - `ItemHistory` (Histórico de preços/status dos anúncios)

  **Tabelas adicionais não solicitadas:**
  - `PaymentMethod` (Métodos de pagamento dos clientes)
  - `FinancialTransaction` (Transações financeiras)
  - `Carrier` (Transportadoras parceiras)
  - `DeliveryTracking` (Rastreamento de entregas)

### Detalhamento das Tabelas Principais

1. **Customer**
   - Armazena dados de clientes e vendedores com flag `is_seller`
   - Campos principais: `customer_id` (PK), `customer_email` (UNIQUE), `first_name`, `last_name`, `birth_date`
   - Auditoria: `created_at`, `updated_at` com atualização automática

2. **Category**
   - Implementa hierarquia de categorias com auto-relacionamento
   - Campos principais: `category_id` (PK), `category_name` (UNIQUE), `parent_id` (FK), `hierarchy_path`
   - Permite navegação eficiente na árvore de categorias

3. **Product**
   - Armazena informações técnicas dos produtos
   - Campos principais: `product_id` (PK), `product_name`, `product_description`, `category_id` (FK)
   - Separado de `Post` para permitir múltiplos anúncios do mesmo produto

4. **Post**
   - Representa anúncios específicos de vendedores
   - Campos principais: `post_id` (PK), `product_id` (FK), `seller_id` (FK), `post_price`, `post_status`
   - Status controlado via ENUM ('active', 'inactive')

5. **Sale**
   - Registra transações de vendas
   - Campos principais: `sale_id` (PK), `buyer_id` (FK), `post_id` (FK), `quantity`, `unit_price`
   - Coluna calculada: `sale_total` (GENERATED ALWAYS AS quantity * unit_price STORED)
   - Status controlado via ENUM ('pending', 'completed', 'cancelled', 'refunded')

6. **ItemHistory**
   - Histórico de preços e status dos anúncios
   - Chave composta: (`post_id`, `snapshot_date`)
   - Permite análise temporal de variações de preço

### Consultas Analíticas (`respuestas_negocio.sql`)

1. **Aniversariantes com Alto Volume de Vendas**
   - Identifica vendedores que fazem aniversário hoje e tiveram mais de 1500 vendas em janeiro/2020
   - Técnicas: Subquery correlacionada, funções de data (MONTH, DAY), filtros booleanos

2. **Top 5 Vendedores por Mês na Categoria Smartphones**
   - Ranking mensal dos melhores vendedores de smartphones em 2020
   - Técnicas avançadas:
     - Common Table Expressions (WITH)
     - Window Functions (ROW_NUMBER, PARTITION BY, ORDER BY)
     - Agregações (SUM) com agrupamento

3. **Stored Procedure para Histórico de Preços**
   - `GenerateDailyItemHistory`: Gera snapshots diários de preços e status
   - Implementa lógica de INSERT ... ON DUPLICATE KEY UPDATE
   - Parâmetros: data alvo (opcional, default = data atual)
   - Uso: `CALL GenerateDailyItemHistory('2020-01-02')`

### Principais Decisões Implementadas:
1. Separação física entre `Product` (dados técnicos) e `Post` (contexto comercial)
2. Uso de DECIMAL(10,2) para valores monetários (preço, custo de frete)
3. Constraints de integridade referencial entre todas as tabelas relacionadas
4. Campos timestamp (created_at/updated_at) para auditoria em todas as entidades
5. Coluna gerada (sale_total) para cálculo automático do total da venda
6. Chaves compostas para otimização de consultas históricas
7. ENUMs para controle de status em diversas entidades

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
   - Política de retentativas com Tenacity:
     - Backoff exponencial entre tentativas (wait_exponential)
     - Relançamento de exceções após esgotar tentativas
### Decisões de Projeto:
1. **Resiliência de Requisições**:
   - Uso da biblioteca Tenacity para retentativas inteligentes
   - Configuração balanceada entre carga do servidor e confiabilidade
2. **Persistência de Dados**:
   - CSV para compatibilidade com BI
   - Checkpoints parciais para recuperação
3. **Separação de Conceitos**: 
    - Camada de autenticação (auth)
    - Lógica de negócio (funcs)
    - Orquestração (main)
4. **Logging**:    
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
        - Implementação de retentativas com @retry do Tenacity:
          - wait=wait_exponential(multiplier=1, max=10)
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