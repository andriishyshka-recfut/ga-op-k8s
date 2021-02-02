resource "helm_release" "prometheus_stack" {
  name      = "prometheus-stack"
  chart     = "${path.module}/kube-prometheus-stack"
  wait      = true
  atomic    = true
  namespace = local.prometheusNs
}
