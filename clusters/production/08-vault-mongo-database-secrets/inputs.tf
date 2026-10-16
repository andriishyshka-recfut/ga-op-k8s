variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "VaultAddress" {}

locals {
  mongodb_main_config = jsondecode(file("${path.module}/config.json"))
  mongodb_auth_config = jsondecode(file("${path.module}/config-auth.json"))

  mongodb_main_admin_path              = "secret/mongo/production"
  mongodb_main_host                    = "mongo-main-rs0.mongo"
  mongodb_main_port                    = "27017"
  mongodb_main_replica_set             = "rs0"
  mongodb_main_connection_url          = "mongodb://{{username}}:{{password}}@${local.mongodb_main_host}:${local.mongodb_main_port}/admin?ssl=false&authSource=admin&readPreference=primaryPreferred&replicaSet=${local.mongodb_main_replica_set}"
  mongodb_main_custom_role_name_prefix = "vault-production"

  mongodb_auth_admin_path              = "secret/mongo/auth"
  mongodb_auth_uri                     = nonsensitive(data.vault_generic_secret.mongodb_auth_admin.data["URI"])
  mongodb_auth_connection_url          = replace(local.mongodb_auth_uri, "mongodb://", "mongodb://{{username}}:{{password}}@")
  mongodb_auth_host                    = "mongo-auth-rs0.mongo-auth"
  mongodb_auth_port                    = "27017"
  mongodb_auth_replica_set             = "rs0"
  mongodb_auth_custom_role_name_prefix = "vault-production-auth"

  kubernetes_auth_path = "secret/kubernetes-${var.Cluster}-${var.Color}"
}

data "vault_generic_secret" "mongodb_main_admin" {
  path = local.mongodb_main_admin_path
}

data "vault_generic_secret" "mongodb_auth_admin" {
  path = local.mongodb_auth_admin_path
}

data "vault_generic_secret" "kubernetes_auth" {
  path = local.kubernetes_auth_path
}
