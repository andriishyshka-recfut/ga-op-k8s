
resource "helm_release" "pushgateway" {
  name              = "pushgateway"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "prometheus-pushgateway"
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
  version           = var.Settings.clusters[var.Cluster].versions.pushgateway.chart_version
  values = [
    templatefile("${path.module}/pushgateway-values.yaml", {})
  ]
}