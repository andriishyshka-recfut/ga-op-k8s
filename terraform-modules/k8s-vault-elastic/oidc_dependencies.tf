data "vault_generic_secret" "saml" {
  count = local.oidcSetup
  path  = local.esValues.saml_gcloud.vault_path
}

resource "kubernetes_secret" "saml" {
  count = local.oidcSetup
  metadata {
    name      = local.esValues.saml_gcloud.secret_name
    namespace = local.esValues.namespace
  }
  data = {
    "metadata" = data.vault_generic_secret.saml.0.data.metadata
  }
}

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
  configAuth = <<EOF
xpack.security.authc.token.enabled: true
xpack.security.authc.realms.oidc.${local.oidcRealmName}:
        order: 2
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
xpack.security.authc.realms.saml.gsuite:
        order: 3
        attributes.principal: "nameid"
        attributes.groups: "groups"
        idp.metadata.path: "/usr/share/elasticsearch/config/saml/metadata"
        idp.entity_id: "https://accounts.google.com/o/saml2?idpid=C04a7ynfq"
        sp.entity_id: "https://kk.regemini.io/"
        sp.acs: "https://kk.regemini.io/api/security/saml/callback"
        sp.logout: "https://kk.regemini.io/logout"
EOF
  oidcConfig = local.oidcSetup == 1 ? { "oidc_config" = local.configAuth } : { "oidc_config" = "" }

}
