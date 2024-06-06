variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  clusterName = "${var.Cluster}-${var.Color}"
  pv_disk_count = var.Color == "red" ? 0 : 1
  diskSize = "50Gi"
  namespace = "sonarqube"
  # minioBucket = "${var.Settings.clusters[var.Cluster].sonarqubeBackuBucket}"
  chart_version = var.Settings.clusters[var.Cluster].versions.sonarqube.helm_chart_version
  image_tag = var.Settings.clusters[var.Cluster].versions.sonarqube.image_tag
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
