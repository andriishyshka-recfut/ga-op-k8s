variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "artifactoryRepoDomain" {}

locals {
  helmVersion             = lookup(var.Settings.clusters[var.Cluster].versions.thanos, "chart_version", "17.3.1")
  thanosVersion           = lookup(var.Settings.clusters[var.Cluster].versions.thanos, "app_version", "v0.40.1")
  thanosBucket            = lookup(var.Settings.clusters[var.Cluster][var.Color].prometheus.thanos, "storage_bucket", "minio-prometheus-thanos-ardent-rarity-239115")
  prometheusNs            = "monitoring"
  thanosConfigFile        = var.Color == "red" ? "red-bitnami-thanos-values.tftpl" : "bitnami-thanos-values.tftpl"
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
