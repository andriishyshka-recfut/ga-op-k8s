variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "GkeClusterConnectionSettings" {}
variable "VaultAddress" {}

data "vault_kv_secrets_list_v2" "db_user_list" {
  mount = "secret"
  name  = "${local.vault_path}/db-users"
}

data "vault_generic_secret" "databases" {
  for_each = local.databases
  path     = "secret/${local.vault_path}/db-users/${each.value}"
}

data "vault_generic_secret" "root_user" {
  path = "secret/${local.vault_path}/root-user"
}

locals {
  vault_path = var.Settings.clusters[var.Cluster].postgres.vault_path
  databases  = nonsensitive(toset(data.vault_kv_secrets_list_v2.db_user_list.names))
  postgres_uri     = "postgres-rw.postgres:5432"

}
