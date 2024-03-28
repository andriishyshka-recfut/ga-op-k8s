variable "Cluster" {}
variable "Color" {}
variable "GkeClusterConnectionSettings" {}
variable "VaultAddress" {}
variable "Settings" {}

locals {
  tektonMainNs       = "tekton-pipelines"
  tektonNs           = "tekton-tasks"
  mongoCredsPath     = "secret/mongo/tekton"
  gkeClusterEndpoint = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken     = var.GkeClusterConnectionSettings.API_KEY
  configPath         = var.Cluster == "production" ? "prod.tfvars.json" : "config.tfvars.json"
}
