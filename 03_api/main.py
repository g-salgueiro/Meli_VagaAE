import pandas as pd
from datetime import datetime
from funcs import buscar_itens, obter_detalhes_item

# Lista de termos para busca
TERMOS_BUSCA = [
    'chromecast',
    'macbook',
    'monitor portátil',
    'Galaxy S23'
]

# Diretório de saída
ARQUIVO_SAIDA = f'output/{datetime.now().strftime("%Y%m%d%H%M%S")}_output.csv'

# Inicialização de variáveis
todos_dados = []
total_itens_coletados = 0
termos_com_erro = []
termos_processados = {termo: False for termo in TERMOS_BUSCA}

print(f'\nIniciando coleta para {len(TERMOS_BUSCA)} termos de busca.')

# Loop principal para cada termo de busca
for termo in TERMOS_BUSCA:
    try:
        print(f' \nProcessando: {termo}')
        
        # Busca IDs de itens usando a função buscar_itens
        ids_itens = buscar_itens(termo, 50)
        
        if not ids_itens:
            print(f'Nenhum item encontrado para "{termo}"')
            continue
        
        # Coleta os detalhes dos itens usando a função obter_detalhes_item
        detalhes_itens = []
        for item_id in ids_itens:
            try:
                detalhes = obter_detalhes_item(item_id)
                
                if detalhes.get('id'):
                    detalhes['termo_busca'] = termo
                    print(f'Coletando detalhes do item {item_id}')
                    detalhes_itens.append(detalhes)
            except Exception as e:
                print(f'Erro ao processar item {item_id}: {str(e)}')
                continue
        
        # Adiciona detalhes aos dados totais. Trato fora do loop para não perder itens caso ocorra erro
        if detalhes_itens:
            todos_dados.extend(detalhes_itens)
            total_itens_coletados += len(detalhes_itens)
            termos_processados[termo] = True
            print(f'Coletados {len(detalhes_itens)} itens para "{termo}"')
    
    except Exception as e:
        termos_com_erro.append(termo)
        print(f'Erro no termo {termo}: {str(e)}')

# Processamento dos dados coletados
if todos_dados:
    # Cria Dataframe
    df = pd.json_normalize(todos_dados)
    
    # Campos desejados. Selecionei os mais relevantes
    campos_desejados = [
        'id', 'title', 'price', 'condition', 'seller.id', 'permalink',
        'warranty', 'original_price', 'termo_busca'
    ]
    
# Selecionando apenas as colunas disponíveis
    colunas_disponiveis = []
    for coluna in campos_desejados:
        if coluna in df.columns:
            colunas_disponiveis.append(coluna)

    df_final = df[colunas_disponiveis]
    
    # Salva em CSV
    df_final.to_csv(ARQUIVO_SAIDA, index=False, encoding='utf-8-sig')
    print(f'\nDados salvos em {ARQUIVO_SAIDA}')
    
    # Verificar termos com erro
    if termos_com_erro:
        print(f'Termos com erro: {termos_com_erro}')
else:
    print('Nenhum dado foi coletado')