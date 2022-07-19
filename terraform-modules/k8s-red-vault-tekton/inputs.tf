variable "Cluster" {}
variable "Color" {}
variable "GkeClusterConnectionSettings" {}
variable "VaultAddress" {}

locals {
  tektonNs           = "tekton-pipelines"
  gkeClusterEndpoint = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken     = var.GkeClusterConnectionSettings.API_KEY
  configPath         = var.Cluster == "production" ? "prod-red.tfvars.json" : "config.tfvars.json"
}
