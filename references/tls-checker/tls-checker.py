import hvac
import requests
import sys
import os
import argparse
from requests.auth import HTTPBasicAuth

parse = argparse.ArgumentParser()
parse.add_argument('--user', '-u', help='basic auth user login (Elasticsearch)')
parse.add_argument('--password', '-p', help='basic auth user password (Elasticsearch)')
parse.add_argument('--project', '-P', help='project in vault', required= True)
parse.add_argument('--vault', '-v', help='Vault address')
args = parse.parse_args()
user = args.user if args.user else os.getenv('BASICAUTH_USER')
password = args.password if args.password else os.getenv('BASICAUTH_PASS')
project = args.project if args.project else ""
vault = args.vault if args.vault else 'https://vault.p.regemini.io'

client = hvac.Client(url=vault)
# client.kv.default_kv_version = 2
certs = client.secrets.kv.read_secret(path='tls-proxy/certs/' + project)["data"]["data"]
domain = client.secrets.kv.read_secret(path='tls-proxy/projects/'+ project)["data"]["data"]["domain"]
certfile = open("tmp.pem","w")
certfile.write(certs["key"])
certfile.write(certs["cert"])
certfile.close()
certca = open("ca.pem","w")
certca.write(certs["ca"])
certca.close()

if user and password:
    basic = HTTPBasicAuth(user, password)
else:
    basic = False
try:
    check = requests.get('https://' + domain, cert='tmp.pem', verify='ca.pem', auth=basic)
except Exception as e: 
    print(e)
    sys.exit()
finally:
    if os.path.exists("tmp.pem"):
        os.remove("tmp.pem")
    if os.path.exists("ca.pem"):
        os.remove("ca.pem")
print('Response code =',check.status_code,"\n",'Response text =',check.text)