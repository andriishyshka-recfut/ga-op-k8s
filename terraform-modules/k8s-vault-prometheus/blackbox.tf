
resource "helm_release" "blackbox_exporter" {
  name              = "blackbox-exporter"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "prometheus-blackbox-exporter"
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
  values = [
    file("${path.module}/blackbox-values.yaml")
  ]
  depends_on = [
        helm_release.prometheus
    ]
}
