
locals {
  istioIngressValues = yamldecode(file("${path.module}/charts/minio-buckets/values.yaml"))
  subDomains         = var.Settings.clusters[var.Cluster][local.activeCluster].minio.buckets
  minioFQDN          = var.Settings.clusters[var.Cluster][local.activeCluster].minio.fqdn
}

resource "helm_release" "minio-subdomains" {
  name      = "minio-buckets"
  namespace = "istio-system"
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
