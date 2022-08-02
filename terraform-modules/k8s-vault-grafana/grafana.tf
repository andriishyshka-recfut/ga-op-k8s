locals {
  grafanaValues = yamldecode(file("${path.module}/values.yaml"))
}

resource "helm_release" "grafana-clients" {
  name       = "grafana-clients"
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  wait       = true
  atomic     = true
  namespace  = "grafana-clients"
  values = [
    yamlencode(local.grafanaValues)
  ]
}
