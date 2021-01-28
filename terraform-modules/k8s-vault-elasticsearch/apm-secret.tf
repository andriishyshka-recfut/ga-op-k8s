
data "kubernetes_secret" "apm_token" {
  metadata {
    name      = "apm-monitoring-apm-token"
    namespace = "monitoring"
  }
  depends_on = [module.monitoring-elastic]
}

resource "kubernetes_secret" "apm_token_maid" {
  metadata {
    name      = "apm-token"
    namespace = "maid"
  }

  data = { "secret-token" = lookup(data.kubernetes_secret.apm_token.data, "secret-token") }

}
