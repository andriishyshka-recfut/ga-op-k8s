data "vault_generic_secret" "saml" {
  for_each = local.saml_list
  path     = each.value.vault_path
}

resource "kubernetes_secret" "saml" {
  for_each = local.saml_list
  metadata {
    name      = each.value.secret_name
    namespace = local.globalSettings.namespace
  }
  data = {
    "metadata" = data.vault_generic_secret.saml[each.key].data.metadata
  }
}

data "vault_generic_secret" "oidc" {
  for_each = local.oidc_list
  path     = each.value.vault_path
}

resource "kubernetes_secret" "oidc" {
  for_each = local.oidc_list
  metadata {
    name      = each.value.secret_name
    namespace = local.globalSettings.namespace
  }
  data = {
    "xpack.security.authc.realms.oidc.${lookup(each.value, "oidc_realm_name", "nope")}.rp.client_secret" = data.vault_generic_secret.oidc[each.key].data.oidc_client_secret
  }
}

locals {
  auth_list  = lookup(local.globalSettings.addons, "authorizations", {})
  oidc_list  = { for name, value in local.auth_list : name => value if value.type == "oidc" }
  saml_list  = { for name, value in local.auth_list : name => value if value.type == "saml" }
  configAuth = <<EOF
    xpack.security.authc.token.enabled: true
%{for auth_key, auth in local.auth_list~}
%{if auth.type == "oidc"~}
    xpack.security.authc.realms.oidc.${auth.oidc_realm_name}:
      order: ${index(keys(local.auth_list), auth_key) + 3}
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
      rp.client_id: ${data.vault_generic_secret.oidc[auth].data.oidc_client_id}
%{else~}
    xpack.security.authc.realms.saml.gsuite:
      order: ${index(keys(local.auth_list), auth_key) + 3}
      attributes.groups: groups
      attributes.principal: nameid
      idp.entity_id: https://accounts.google.com/o/saml2?idpid=C04a7ynfq
      idp.metadata.path: /usr/share/elasticsearch/config/saml/${auth.secret_name}/metadata
      sp.acs: https://${auth.domain}/api/security/saml/callback
      sp.entity_id: https://${auth.domain}/
      sp.logout: https://${auth.domain}/logout
%{endif~}
%{endfor~}
EOF
}

