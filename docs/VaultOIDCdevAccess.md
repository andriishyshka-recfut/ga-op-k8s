Here are sample steps to provide access for devs:

1. Create policy
```
vault policy write magescanner - << EOF

path "secret/magescanner/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/" {
  capabilities = ["list"]
}
EOF


```
2. Create Role for access
```
export oidc_client_id=$(vault read  -field=oidc_client_id secret/oidc_google_test)
vault write auth/oidc/role/magescanner \
    bound_audiences="${oidc_client_id}" \
    user_claim="sub"\
    policies=magescanner \
    allowed_redirect_uris="https://vault.infra.digaweb.com/ui/vault/auth/oidc/oidc/callback" \
    ttl=1h

vault list auth/oidc/role

```
3. Test by login from browser with role magescanner
