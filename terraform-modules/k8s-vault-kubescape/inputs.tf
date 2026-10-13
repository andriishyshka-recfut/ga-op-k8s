variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  clusterName = "${var.Cluster}-${var.Color}"
  minioBucket = "${var.Settings.clusters[var.Cluster].kubescapeReportsBucket}"
  namespace   = "kubescape"
  version     = lookup(var.Settings.clusters[var.Cluster].versions.kubescape, "image_tag", "3.0.8")
  values = {
    tag = local.version
    minioBucket = local.minioBucket
    minioSidecar = lookup(var.Settings.clusters[var.Cluster].versions.kubescape, "minio_sidecar", "minio/mc")
    schedulerTag = "v0.2.2"
    clusterName = "${var.Cluster}-${var.Color}"
  }
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
