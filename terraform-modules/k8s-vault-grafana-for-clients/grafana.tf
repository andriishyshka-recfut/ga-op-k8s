# locals {
#   grafanaValues = yamldecode(file("${path.module}/values.yaml"))
# }
data "vault_generic_secret" "elastic" {
  path = "secret/elasticsearch-admin/elastic"
}
data "vault_generic_secret" "grafana" {
  path = local.grafanaSecretpath
}

resource "kubernetes_secret" "grafana_okta_client_secret" {
  metadata {
    name      = "grafana-okta-client-secret"
    namespace = local.grafanaNs
  }
  data = {
    client_secret = data.vault_generic_secret.okta_oidc.data.client_secret
  }
}
resource "helm_release" "grafana-clients" {
  name       = "grafana-clients"
  chart      = "grafana"
  version    = local.helmVersion
  repository = "https://grafana.github.io/helm-charts"
  wait       = true
  atomic     = true
  # force_update  = true
  namespace = local.grafanaNs
  values    = [templatefile("${path.module}/templates/grafana.tftpl", { grafana = local.grafanaSettings })]
}
