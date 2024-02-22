variable "Cluster" {}
variable "Color" {}
variable "GkeClusterConnectionSettings" {}
variable "VaultAddress" {}

locals {
  tektonMainNs       = "tekton-pipelines"
  tektonNs           = "tekton-tasks"
  mongoCredsPath     = "secret/mongo/tekton"
  gkeClusterEndpoint = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken     = var.GkeClusterConnectionSettings.API_KEY
  configPath         = var.Cluster == "production" ? "prod.tfvars.json" : "config.tfvars.json"
  registry_server    = "harbor.regemini.io"
}
