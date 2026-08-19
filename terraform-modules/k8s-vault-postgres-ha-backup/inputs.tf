variable "Cluster" {}
variable "Settings" {}
variable "PostgresqlHaProfile" {}

data "vault_kv_secrets_list_v2" "db_user_list" {
  mount = "secret"
  name  = "${local.vault_path}/db-users"
}

locals {
  cluster_settings     = var.Settings.clusters[var.Cluster]
  postgres_ha_settings = local.cluster_settings["postgresql-ha"][var.PostgresqlHaProfile]

  cluster_name = local.postgres_ha_settings.cluster_name
  namespace    = local.postgres_ha_settings.namespace
  vault_path   = local.postgres_ha_settings.vault_path

  root_secret_name = lookup(local.postgres_ha_settings, "root_secret_name", "${local.cluster_name}-superuser")

  backup_settings         = lookup(local.postgres_ha_settings, "backup", {})
  backup_enabled          = lookup(local.backup_settings, "enabled", false) && local.backup_bucket != ""
  backup_host             = lookup(local.backup_settings, "host", "${local.cluster_name}-pgpool")
  backup_port             = tostring(lookup(local.backup_settings, "port", 5432))
  backup_image            = lookup(local.backup_settings, "image", "harbor.regemini.io/op/postgres-minio-backup")
  backup_tag              = lookup(local.backup_settings, "tag", "pg17-aws")
  backup_cli              = lookup(local.backup_settings, "cli", "aws")
  backup_minio_vault_path = lookup(local.backup_settings, "minio_vault_path", "secret/minio/users")
  backup_minio_user       = lookup(local.backup_settings, "minio_user", "backup")
  backup_minio_alias      = lookup(local.backup_settings, "minio_alias", "backup")
  backup_minio_endpoint   = lookup(local.backup_settings, "minio_endpoint", "http://minio.minio:9000")
  backup_bucket           = lookup(local.backup_settings, "bucket", "minio-backup-${var.Settings.gcpProject}")
  backup_path             = trim(lookup(local.backup_settings, "path", "postgresql-ha/${local.cluster_name}"), "/")
  backup_schedule         = lookup(local.backup_settings, "schedule", "0 2 * * *")
  backup_retention        = lookup(local.backup_settings, "retention", "7d")
  backup_secret_name      = lookup(local.backup_settings, "secret_name", "${local.cluster_name}-backup-minio")
  backup_globals_enabled  = lookup(local.backup_settings, "globals_enabled", true)

  backup_database_requests = distinct([
    for db in lookup(local.backup_settings, "databases", []) : trimspace(db)
    if trimspace(db) != ""
  ])
  db_user_names = sort(nonsensitive(data.vault_kv_secrets_list_v2.db_user_list.names))
  backup_databases = sort([
    for db in local.backup_database_requests : db
    if contains(local.db_user_names, db)
  ])
}
