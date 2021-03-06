data "vault_generic_secret" "oidc_secrets" {
  path = "secret/oidc_google_prod"
}

# data "vault_generic_secret" "grafana" {
#   path = "secret/grafana"
# }

resource "helm_release" "prometheus-kafka-exporter" {
  name              = "prometheus-kafka-exporter"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "prometheus-kafka-exporter"
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
  values = [
    file("${path.module}/values.yaml")
  ]
}
