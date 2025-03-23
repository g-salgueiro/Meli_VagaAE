import requests
from typing import List, Dict
from auth import TOKEN
from tenacity import retry, wait_exponential

def tratar_erro_http(status_code: int) -> str:
    """Retorna mensagem amigável para códigos de erro HTTP específicos

    Args:
        status_code (int): Código de status HTTP recebido

    Returns:
        str: Mensagem de erro contextualizada em português
    """
    mensagens_erro = {
        400: "Erro 400 - Erro de request",
        401: "Erro 401 - Usuário não autenticado",
        403: "Erro 403 - Usuário não autorizado",
        429: "Erro 429 - Muitas requisições, aguarde",
        500: "Erro 500 - Erro interno de servidor",
        503: "Erro 503 - Servidor indisponível",
        504: "Erro 504 - Gateway Timeout"
    }
    return mensagens_erro.get(status_code, f"Erro {status_code} - Erro desconhecido")

@retry(wait=wait_exponential(multiplier=1, min=2, max=30))
def buscar_itens(query: str, limit: int = 50, offset: int = 0) -> List[str]:
    """Busca itens no Mercado Livre por query e retorna lista de IDs

    Args:
        query (str): Termo de busca para pesquisar no Mercado Livre
        limit (int, optional): Quantidade máxima de resultados. Padrão: 50

    Returns:
        List[str]: Lista de IDs dos itens encontrados

    Raises:
        Exception: Erros de HTTP com mensagens tratadas ou erros genéricos
    """
    headers = {'Authorization': f'Bearer {TOKEN}'}
    url = f'https://api.mercadolibre.com/sites/MLA/search?q={query}&limit={limit}&offset={offset}'
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return [item['id'] for item in response.json()['results']]
    except requests.exceptions.HTTPError as e:
        status_code = e.response.status_code
        mensagem = tratar_erro_http(status_code)
        raise Exception(mensagem) from e
    except Exception as e:
        raise Exception(f"Erro ao buscar itens: {str(e)}") from e

@retry(wait=wait_exponential(multiplier=1, min=2, max=30))
def obter_detalhes_item(item_id: str) -> Dict:
    """Obtém detalhes completos de um item específico

    Args:
        item_id (str): ID do item no Mercado Livre

    Returns:
        Dict: Dicionário com metadados completos do item

    Raises:
        Exception: Erros de HTTP com mensagens tratadas ou erros genéricos
    """
    headers = {'Authorization': f'Bearer {TOKEN}'}
    url = f'https://api.mercadolibre.com/items/{item_id}'
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.HTTPError as e:
        status_code = e.response.status_code
        mensagem = tratar_erro_http(status_code)
        raise Exception(mensagem) from e
    except Exception as e:
        raise Exception(f"Erro ao obter detalhes do item: {str(e)}") from e