variable "Settings" {}
variable "Cluster" {}

variable "OidcSecretVaultPath" {
  default = "secret/oidc_google_prod"
}


locals {
  prometheusNs = "monitoring"
  prometheusExtUrl = lookup(var.Settings.clusters[var.Cluster], "prometheusExtUrl",
  "http://localhost:9090") != "http://localhost:9090" ? var.Settings.clusters[var.Cluster].prometheusExtUrl : "http://localhost:9090"
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
