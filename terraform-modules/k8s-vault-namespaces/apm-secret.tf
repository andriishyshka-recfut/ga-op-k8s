data "vault_generic_secret" "apm_token" {
  count = local.use_apm
  path = "secret/apm/mon-${var.Color}"
}

resource "kubernetes_secret" "apm_token_secrets" {
  for_each = local.injectApmSecrets
  metadata {
    name      = "apm-token"
    namespace = each.key
  }

  data = {
    secret-token = data.vault_generic_secret.apm_token[0].data.token
  }

  depends_on = [
    kubernetes_namespace.ns
  ]
}
