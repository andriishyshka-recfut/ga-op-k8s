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
    "xpack.security.authc.realms.oidc.${local.oidcRealmName}.rp.client_secret" = data.vault_generic_secret.oidc.0.data.oidc_client_secret
  }

}

locals {
  clientId   = local.oidcSetup == 1 ? data.vault_generic_secret.oidc.0.data.oidc_client_id : ""
  config     = <<EOF
xpack.security.authc.token.enabled: true
xpack.security.authc.realms.oidc.${local.oidcRealmName}:
        order: 2
        rp.response_type: code
        rp.redirect_uri: https://${local.monUrl}/api/security/oidc/callback
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

EOF
  oidcConfig = local.oidcSetup == 1 ? { "oidc_config" = local.config } : { "oidc_config" = "" }

}
