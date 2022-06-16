resource "helm_release" "minio-subdomains" {
  name      = "minio"
  namespace = "istio-ingress"
  chart     = "${path.module}/charts/minio-buckets"
  wait      = true
  atomic    = true
  values = [
    yamlencode(local.istioIngressValues)
  ]
  set {
    name  = "domain"
    value = local.minioFQDN
  }
  set {
    name  = "buckets"
    value = "{${join(",", local.subDomains)}}"
    type  = "auto"
  }
}
