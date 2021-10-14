

variable "GkeClusterConnectionSettings" {}
variable "VaultAddress" { }

locals {
  gkeClusterEndpoint      = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken          = var.GkeClusterConnectionSettings.API_KEY
  camelNs = "camel-k"
}
