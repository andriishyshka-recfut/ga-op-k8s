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
  cluster_name     = var.Settings.clusters[var.Cluster].postgres.cluster_name
  namespace        = var.Settings.clusters[var.Cluster].postgres.namespace
  vault_path       = var.Settings.clusters[var.Cluster].postgres.vault_path
  disk_count       = var.Settings.clusters[var.Cluster].postgres.replicas
  zones            = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
  operator_version = var.Settings.clusters[var.Cluster].postgres.operator_chart_version
  databases        = nonsensitive(toset(data.vault_kv_secrets_list_v2.db_user_list.names))
  db_user_pass     = { for name in local.databases : name => tomap(data.vault_generic_secret.databases[name].data) }
  minio = {
    url    = "http://minio.minio:9000"
    bucket = "minio-backup-${var.Settings.gcpProject}"
    path   = "cnpg"
  }
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
    namespace               = local.namespace
  })
}



output "test" {
  value = local.db_user_pass
}
