resource "helm_release" "minio-subdomains" {
  name      = "minio"
  namespace = "istio-ingress"
  chart     = "${path.module}/charts/minio-buckets"
  wait      = true
  atomic    = true
  values    = [templatefile("${path.module}/templates/ingress.tftpl", { Settings = local.values })]
}
