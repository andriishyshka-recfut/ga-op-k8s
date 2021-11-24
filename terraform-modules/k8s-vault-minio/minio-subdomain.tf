locals {
  istioIngressValues = yamldecode(file("${path.module}/charts/istioIngress/values.yaml"))
  subDomains         = var.Settings.clusters[var.Cluster].minioBucketIngress
  projectName        = var.Settings.gcpProject
  minioFQDN          = var.Settings.clusters[var.Cluster][var.Color].minio.fqdn
}

resource "helm_release" "minio-subdomains" {
  name      = "buckets_minio"
  namespace = "istio-system"
  chart     = "${path.module}/charts/istioIngress"
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
    value = local.subDomains
    type  = "auto"
  }
}
