data "vault_kv_secret_v2" "okta" {
  mount = "secret"
  name  = "misc/oidc/okta/vault"
}

resource "vault_jwt_auth_backend" "okta" {
  description        = "Recorded Future OKTA auth"
  path               = "okta"
  type               = "oidc"
  oidc_discovery_url = data.vault_kv_secret_v2.okta.data.issuer
  oidc_client_id     = data.vault_kv_secret_v2.okta.data.client_id
  oidc_client_secret = data.vault_kv_secret_v2.okta.data.client_secret
  default_role       = "okta_default_role"
  tune {
    listing_visibility = "unauth"
    default_lease_ttl  = "768h"
    max_lease_ttl      = "768h"
    token_type         = "default-service"
  }
}

resource "vault_jwt_auth_backend_role" "okta" {
  backend               = vault_jwt_auth_backend.okta.path
  role_name             = "okta_default_role"
  oidc_scopes           = ["openid", "email", "profile", "groups"]
  bound_audiences       = [data.vault_kv_secret_v2.okta.data.client_id]
  bound_claims          = { groups = join(",", keys(local.vault_groups)) }
  groups_claim          = "groups"
  user_claim            = "sub"
  role_type             = "oidc"
  allowed_redirect_uris = ["https://vault.p.regemini.io/ui/vault/auth/okta/oidc/callback", "http://localhost:8250/oidc/callback"]
  token_ttl             = 86400
  depends_on            = [vault_jwt_auth_backend.okta]
}

locals {
  vault_groups = {
    APP-GA-OP         = ["admin"],
    APP-GA-VaultP-ETL = ["oidc-recordedfuture"],
    APP-GA-PM         = ["oidc-pm"]
  }
}

resource "vault_identity_group" "group" {
  for_each   = local.vault_groups
  name       = each.key
  type       = "external"
  policies   = each.value
  depends_on = [vault_jwt_auth_backend_role.okta]
}

resource "vault_identity_group_alias" "group_alias" {
  for_each       = local.vault_groups
  name           = each.key
  mount_accessor = vault_jwt_auth_backend.okta.accessor
  canonical_id   = vault_identity_group.group[each.key].id
  depends_on     = [vault_identity_group.group]
}

