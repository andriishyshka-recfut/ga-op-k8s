variable "Settings" {}
variable "Color" {}
variable "Cluster" {}

locals {
  namespace         = "monitoring"
  elasticSecretName = var.Cluster == "production" ? "filebeat-${var.Color}-elastic-credentials" : "prod-mon-elastic-creds"
 }
