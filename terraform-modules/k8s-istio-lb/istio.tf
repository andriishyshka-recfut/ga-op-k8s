# Need to replace
resource "helm_release" "istio_ingress_lb" {
  for_each   = local.istio_ingresses
  name       = "istio-ingressgateway-${each.key}"
  chart      = "gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = var.Settings.clusters[var.Cluster].versions.istio.helm_version
  wait       = true
  atomic     = true
  namespace  = "istio-ingress"
  values = [
    templatefile("${path.module}/values.tftpl", { settings = each.value })
  ]
}
