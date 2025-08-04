variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  values = {
    domain  = var.Settings.clusters[var.Cluster][var.Color].minio.fqdn
    buckets = join(",", var.Settings.clusters[var.Cluster][var.Color].minio.buckets)
  }
}
