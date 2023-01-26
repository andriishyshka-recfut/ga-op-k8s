variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  clusterName = "${var.Cluster}-${var.Color}"
  minioBucket = "${var.Settings.clusters[var.Cluster].kubescapeReportsBucket}"
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
