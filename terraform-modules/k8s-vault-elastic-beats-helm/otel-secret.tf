data "vault_generic_secret" "elastic_apm_api_key" {
  path     = "secret/mw/otel/api-key"
}

resource "kubernetes_secret" "elastic_apm_api_key" {
  metadata {
    name      = "otel-elastic-api-key"
    namespace = "monitoring"
  }
  data = {
    "encoded" = data.vault_generic_secret.elastic_apm_api_key.data["encoded"]
  }
  depends_on = [data.vault_generic_secret.elastic_apm_api_key]
}