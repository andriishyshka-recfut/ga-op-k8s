

variable "GkeClusterConnectionSettings" {}
variable "VaultAddress" { }
variable "Cluster" {}

locals {
  gkeClusterEndpoint      = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken          = var.GkeClusterConnectionSettings.API_KEY
  camelNs = "camel-k"
  installCount = var.Cluster == "production" ? 1 : 0
}
