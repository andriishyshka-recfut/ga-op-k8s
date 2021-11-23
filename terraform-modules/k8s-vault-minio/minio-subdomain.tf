locals {
  istioIngressValues = yamldecode(file("${path.module}/charts/istioIngress/values.yaml"))
  subDomains         = var.Settings.clusters[var.Cluster].minioBucketIngress
  projectName        = var.Settings.gcpProject
  minioFQDN          = var.Settings.clusters[var.Cluster][var.color].minio.fqdn
}

resource "helm_release" "minio-subdomains" {
  for_each  = toset(local.subDomains)
  name      = replace(each.key, "-${local.projectName}", "")
  namespace = "istio-system"
  chart     = "${path.module}/charts/istioIngress"
  wait      = true
  atomic    = true
  values = [
    yamlencode(local.istioIngressValues)
  ]
  set {
    name  = "domain"
    value = "${each.key}.${local.minioFQDN}"
  }
}
