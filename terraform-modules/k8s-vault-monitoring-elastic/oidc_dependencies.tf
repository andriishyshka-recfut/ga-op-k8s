data "vault_generic_secret" "oidc" {
  count = local.oidcSetup
  path  = local.esValues.oidc_gcloud.vault_path
}

resource "kubernetes_secret" "oidc" {
  count = local.oidcSetup
  metadata {
    name      = local.esValues.oidc_gcloud.secret_name
    namespace = local.esValues.namespace
  }

  data = {
    "xpack.security.authc.realms.oidc.${local.oidcRealmName}.rp.client_secret" = data.vault_generic_secret.oidc.0.data.client_secret
  }
}

data "vault_generic_secret" "okta" {
  path = "secret/misc/oidc/okta/monitoring_kibana"
}

resource "kubernetes_secret" "okta" {
  metadata {
    name      = "okta"
    namespace = local.esValues.namespace
  }
  data = {
    "xpack.security.authc.realms.oidc.okta.rp.client_secret" = data.vault_generic_secret.okta.data.client_secret
  }
}

locals {
  clientId   = local.oidcSetup == 1 ? data.vault_generic_secret.oidc.0.data.client_id : ""
  config     = <<EOF
xpack.security.authc.token.enabled: true
xpack.security.authc.realms.oidc.${local.oidcRealmName}:
        order: 0
        rp.response_type: code
        rp.redirect_uri: https://${var.OidcRedirectUri}/api/security/oidc/callback
        op.issuer: https://accounts.google.com
        op.authorization_endpoint: https://accounts.google.com/o/oauth2/v2/auth
        op.token_endpoint: https://oauth2.googleapis.com/token
        op.jwkset_path: https://www.googleapis.com/oauth2/v3/certs
        claims.principal: "email"
        rp.requested_scopes:
          - email
          - openid
          - profile
        rp.client_id: ${local.clientId}
xpack.security.authc.realms.oidc.okta:
      order: 1
      rp.response_type: "code" 
      rp.redirect_uri: https://${var.OidcRedirectUri}/api/security/oidc/callback
      op.issuer: ${data.vault_generic_secret.okta.data.issuer}
      op.authorization_endpoint: "${data.vault_generic_secret.okta.data.issuer}/oauth2/v1/authorize"
      op.jwkset_path: "${data.vault_generic_secret.okta.data.issuer}/oauth2/v1/keys"
      op.token_endpoint: "${data.vault_generic_secret.okta.data.issuer}/oauth2/v1/token"
      op.endsession_endpoint: "${data.vault_generic_secret.okta.data.issuer}/oauth2/v1/logout"
      claims.principal: "email"
      claims.groups: "groups"
      rp.requested_scopes:
        - email
        - openid
        - profile
        - groups
      rp.client_id: ${data.vault_generic_secret.okta.data.client_id}
EOF
  oidcConfig = local.oidcSetup == 1 ? { "oidc_config" = local.config } : { "oidc_config" = "" }

}
