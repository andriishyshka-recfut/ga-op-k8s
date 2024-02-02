variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

variable "OidcSecretVaultPath" {
  default = "secret/oidc_google_prod"
}


locals {
  helmVersion      = lookup(var.Settings.clusters[var.Cluster][var.Color].versions.prometheus, "helm_version", "17.0.0")
  prometheusNs     = "monitoring"
  prometheusExtUrl = lookup(var.Settings.clusters[var.Cluster][var.Color].prometheus, "prometheusExtUrl", "http://localhost:9090")
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
