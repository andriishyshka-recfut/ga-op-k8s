variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  clusterName = "${var.Cluster}-${var.Color}"
  minioBucket = "${var.Settings.clusters[var.Cluster].kubescapeReportsBucket}"
  namespace   = "kubescape"
  version     = lookup(var.Settings.clusters[var.Cluster][var.Color].versions.kubescape, "image_tag", "3.0.8")
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
