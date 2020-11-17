
data "kubernetes_secret" "apm-token" {
  metadata {
    name      = "apm-monitoring-apm-token"
    namespace = "monitoring"
  }
}

resource "kubernetes_secret" "apm-token" {
  metadata {
    name      = "apm-token"
    namespace = local.ns
  }

  data = { "secret-token" = lookup(data.kubernetes_secret.apm-token.data, "secret-token") }

}
