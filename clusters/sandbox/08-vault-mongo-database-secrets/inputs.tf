variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "VaultAddress" {}

locals {
  config = jsondecode(file("${path.module}/config.json"))

  mongodb_host                    = "mongo-main-rs0.mongo"
  mongodb_port                    = "27017"
  mongodb_replica_set             = "rs0"
  mongodb_connection_url          = "mongodb://{{username}}:{{password}}@${local.mongodb_host}:${local.mongodb_port}/admin?ssl=false&authSource=admin&readPreference=primaryPreferred&replicaSet=${local.mongodb_replica_set}"
  mongodb_admin_path              = "secret/mongo6/main"
  mongodb_custom_role_name_prefix = "vault-sandbox"
  kubernetes_auth_path            = "secret/kubernetes-${var.Cluster}-${var.Color}"
}

data "vault_generic_secret" "mongodb_admin" {
  path = local.mongodb_admin_path
}

data "vault_generic_secret" "kubernetes_auth" {
  path = local.kubernetes_auth_path
}
