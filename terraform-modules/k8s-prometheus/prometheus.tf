resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  values = [
    file("${path.module}/values.yaml")
  ]
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
}
