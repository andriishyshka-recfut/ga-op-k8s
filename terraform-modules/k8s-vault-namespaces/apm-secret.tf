data "vault_generic_secret" "apm_token" {
  for_each = local.injectApmSecrets
  path = "secret/apm/${each.key}-${var.Color}"
}

resource "kubernetes_secret" "apm_token_secrets" {
  for_each = local.injectApmSecrets
  metadata {
    name      = "apm-token"
    namespace = each.key
  }

  data = {
    secret-token = data.vault_generic_secret.apm_token[each.key].data.token
  }

  depends_on = [
    kubernetes_namespace.ns
  ]
}
