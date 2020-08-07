
# Step by step guide to create new cluster.


### Here will be steps to provision new cluster with terraform

1. First make sure all stuff from terraform-base/ is done.
2. Connect to Wireguard VPN
3. Update .env file with appropriate project settings and `source .env`
4. Update `config.tfvars.json`  if required
5. Configure OAuth2.0 for vault SSO.
  a. Make sure that consent screen is [configured](https://support.google.com/cloud/answer/6158849?hl=en#userconsent)
  b. Create [OpenID Client](https://support.google.com/cloud/answer/6158849)
  c. Configure Callback URLs as authorized domains of your client. Next required for vault(localhost required for vault cli login):
      ```
      https://{{ settings.blue.vault.url}}/ui/vault/auth/oidc/oidc/callback
      http://localhost:8250/oidc/callback
      ```
6. Check `main.tf` and configure proper `backend`. Bucket from base setup expected here.
7. Set env variables  run terraform. For initial provisioning blue cluster should be used first, becouse only blue will create  DNS zone and records(alias works only at zsh).
```
zsh

export oidc_discovery_url="https://accounts.google.com"
export oidc_client_id="Client ID From Previous Step"
export oidc_client_secret="Client Secret From Previous Step"

cd tf-blue/
tf init
tf apply
```

8. Commit and push if anything was changed.
