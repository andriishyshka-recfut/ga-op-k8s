variable Cluster {}
variable Color {}
variable "GkeClusterConnectionSettings" {}

locals {
  gkeClusterEndpoint      = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken          = var.GkeClusterConnectionSettings.API_KEY
  configPath = var.Cluster == "production" ? "prod.tfvars.json" : "config.tfvars.json"
}
