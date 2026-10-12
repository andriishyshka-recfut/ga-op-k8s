variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "artifactoryRepoDomain" {}

variable "OidcSecretVaultPath" {
  default = "secret/oidc_google_prod"
}


locals {
  helmVersion      = lookup(var.Settings.clusters[var.Cluster].versions.prometheus, "helm_version", "17.0.0")
  prometheusNs     = "monitoring"
  grafanaRole      = var.Cluster == "production" ? "Viewer" : "Editor"
  prometheusExtUrl = lookup(var.Settings.clusters[var.Cluster][var.Color].prometheus, "prometheusExtUrl", "http://localhost:9090")
  vortex           = var.Cluster == "production" ? 1 : 0
}
