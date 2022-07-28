variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

variable "OidcSecretVaultPath" {
  default = "secret/oidc_google_prod"
}


locals {
  helmVersion          = lookup(var.Settings.clusters[var.Cluster][var.Color].prometheus, "helm_version", "17.0.0")
  prometheusNs         = "monitoring"
  grafanaRole          = var.Cluster == "production" ? "Viewer" : "Editor"
  prometheusExtUrl     = lookup(var.Settings.clusters[var.Cluster][var.Color].prometheus, "prometheusExtUrl", "http://localhost:9090")
  prometheusConfigFile = var.Color == "red" ? "red-kube-prometheous-stack-values.yaml" : "kube-prometheous-stack-values.yaml"
  grafanaSecretpath    = var.Color == "red" ? "secret/red/grafana" : "secret/grafana"
  slackSecretPath      = var.Color == "red" ? "secret/red/slack/prometheus" : "secret/slack/prometheus"
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
