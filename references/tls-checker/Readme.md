# This tool is use for checking our tls proxy project connection.
## Install requirements:
```
pip3 install -r requirements.txt
```
## Preconfigure envs:
```
export VAULT_TOKEN=${Your token}
```
## Usage:
For the first you need to know project name in vault, and you can browse it in web interface of vault by url - `https://vault.p.regemini.io/ui/vault/secrets/secret/list/tls-proxy/projects` or you can get it from terminal(if you have installed vault cli for sure).
```
export VAULT_ADDR=https://vault.p.regemini.io
vault kv list -mount=secret tls-proxy/projects
```
and run it to check:
```
python3 tls-checker.py -P ${project name}
```
Also you can send basic auth (we used it on vortex) with keys -u ${user} -p {password}