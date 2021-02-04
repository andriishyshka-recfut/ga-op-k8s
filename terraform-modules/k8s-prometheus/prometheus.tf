resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-community/kube-prometheus-stack"
  values = [
    "${path.module}/values.yaml"
    # "${file("./values.yaml")}"
  ]
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
}
