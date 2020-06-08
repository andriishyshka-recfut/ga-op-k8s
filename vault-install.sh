cd k8s/




vault policy write admin vault-admin-policy.hcl

vault auth enable oidc

vault write auth/oidc/config \
        oidc_discovery_url="https://accounts.google.com" \
        oidc_client_id="921970745198-3541scevmu5oogrlucmu0poh7kn9a7ms.apps.googleusercontent.com" \
        oidc_client_secret="cIboHURcJYBg-1wpUSvhoNF6" \
        default_role="admin"



vault write auth/oidc/role/admin \
        bound_audiences="921970745198-3541scevmu5oogrlucmu0poh7kn9a7ms.apps.googleusercontent.com" \
        allowed_redirect_uris="https://vault.infra.digaweb.io/ui/vault/auth/oidc/oidc/callback" \
        allowed_redirect_uris="http://localhost:8250/oidc/callback" \
        user_claim="sub" \
        policies="admin"
