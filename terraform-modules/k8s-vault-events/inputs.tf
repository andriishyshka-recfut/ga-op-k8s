variable "Settings" {}
variable "Color" {}
variable "Cluster" {}

locals {
  namespace = "monitoring"
  elasticSecretName = var.Cluster == "production" ? "elastic-credentials" : "prod-mon-elastic-creds"
}
