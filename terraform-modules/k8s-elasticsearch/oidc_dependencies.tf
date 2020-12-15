data "vault_generic_secret" "oidc" {
  count = local.oidc_setup
  path  = local.es_values.oidc_gcloud.vault_path
}

resource "kubernetes_secret" "oidc" {
  count = local.oidc_setup
  metadata {
    name      = local.es_values.oidc_gcloud.secret_name
    namespace = local.es_values.namespace
  }

  data = {
    "xpack.security.authc.realms.oidc.${local.oidc_realm_name}.rp.client_secret" = data.vault_generic_secret.oidc.0.data.oidc_client_secret
  }

}

# try to mount oidc config as configmap
# https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-bundles-plugins.html
# resource "kubernetes_config_map" "oidc" {
#   count = local.oidc_setup
#   metadata {
#     name      = local.es_values.oidc_gcloud.configmap_name
#     namespace = local.es_values.namespace
#   }
#
#   data = {
#   }
#
locals {
  config      = <<EOF
xpack.security.authc.token.enabled: true
xpack.security.authc.realms.oidc.${local.oidc_realm_name}:
        order: 2
        rp.response_type: code
        rp.redirect_uri: https://${local.kibana_values.istio_gateway_fqdn}/api/security/oidc/callback
        op.issuer: https://accounts.google.com
        op.authorization_endpoint: https://accounts.google.com/o/oauth2/v2/auth
        op.token_endpoint: https://oauth2.googleapis.com/token
        op.jwkset_path: https://www.googleapis.com/oauth2/v3/certs
        claims.principal: "email"
        rp.requested_scopes:
          - email
          - openid
          - profile
        rp.client_id: ${data.vault_generic_secret.oidc.0.data.oidc_client_id}

EOF
  oidc_config = local.oidc_setup == 1 ? { "oidc_config" = local.config } : { "oidc_config" = "" }

}
