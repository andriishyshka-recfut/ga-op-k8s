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
  cluster_settings    = var.Settings.clusters[var.Cluster]
  postgres_settings   = local.cluster_settings.postgres
  persistent_postgres = local.cluster_settings.persistent_resources.permanentDisks.services.postgres.postgres
  zones               = local.cluster_settings.persistent_resources.permanentDisks.zones

  cluster_name      = local.postgres_settings.cluster_name
  namespace         = local.postgres_settings.namespace
  vault_path        = local.postgres_settings.vault_path
  disk_count        = local.persistent_postgres.count
  disk_prefix       = local.persistent_postgres.prefix
  pv_selector_label = local.disk_prefix
  operator_version  = local.postgres_settings.operator_chart_version
  postgres_uri      = "postgres-rw.postgres:5432"
  databases         = nonsensitive(toset(data.vault_kv_secrets_list_v2.db_user_list.names))
  db_user_pass      = { for name in local.databases : name => tomap(data.vault_generic_secret.databases[name].data) }
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
