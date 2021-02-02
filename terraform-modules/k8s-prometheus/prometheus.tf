resource "helm_release" "prometheus" {
  name      = "prometheus"
  chart     = "${path.module}/kube-prometheus-stack"
  wait      = true
  atomic    = true
  namespace = local.prometheusNs
}
