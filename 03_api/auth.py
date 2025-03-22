import requests

# Varáveis de autenticação. Sei que o ideal é usar como variável de ambiente, mas coloquei 
# em hardcode caso queiram testar
#  
client_id = '1652905443922169'
client_secret = '6P50MuIFH1OhmAofK03Ss4OvKIBG2oSr'
refresh_token = 'TG-67df0e064bdcce00013de594-61712057'
TOKEN = 'APP_USR-1652905443922169-032215-7a0ec4e9b0288c67c9f5235e99fb8685-61712057'
url = "https://api.mercadolibre.com/oauth/token"

payload = f'grant_type=refresh_token&client_id={client_id}&client_secret={client_secret}&refresh_token={refresh_token}'
headers = {
    'accept': 'application/json',
    'content-type': 'application/x-www-form-urlencoded'
}

response = requests.request("POST", url, headers=headers, data=payload)