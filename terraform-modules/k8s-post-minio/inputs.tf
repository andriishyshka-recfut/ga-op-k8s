variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  istioIngressValues = yamldecode(file("${path.module}/charts/minio-buckets/values.yaml"))
  subDomains         = var.Settings.clusters[var.Cluster][var.Color].minio.buckets
  minioFQDN          = var.Settings.clusters[var.Cluster][var.Color].minio.fqdn
}
