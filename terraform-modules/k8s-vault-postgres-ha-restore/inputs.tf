variable "Cluster" {}
variable "Settings" {}
variable "PostgresqlHaProfile" {}
variable "RestoreDatabase" {
  default = ""
}
variable "RestoreBackupTimestamp" {
  default = ""
}
variable "RestoreJobName" {
  default = ""
}

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
  backup_secret_name      = lookup(local.backup_settings, "secret_name", "${local.cluster_name}-backup-minio")

  backup_mc_env  = "MC_HOST_${replace(upper(local.backup_minio_alias), "-", "_")}"
  backup_mc_host = startswith(local.backup_minio_endpoint, "https://") ? "https://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@${trimsuffix(trimprefix(local.backup_minio_endpoint, "https://"), "/")}" : "http://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@${trimsuffix(trimprefix(local.backup_minio_endpoint, "http://"), "/")}"

  db_user_names = sort(nonsensitive(data.vault_kv_secrets_list_v2.db_user_list.names))

  restore_database          = trimspace(var.RestoreDatabase)
  restore_backup_timestamp  = trimspace(var.RestoreBackupTimestamp)
  restore_job_name_override = trimspace(var.RestoreJobName)
  restore_enabled = (
    local.backup_enabled &&
    local.restore_database != "" &&
    local.restore_backup_timestamp != "" &&
    contains(local.db_user_names, local.restore_database)
  )
  restore_backup_filename      = local.restore_enabled ? "${local.restore_database}-${local.restore_backup_timestamp}.dump" : ""
  restore_owner_filename       = local.restore_enabled ? "${local.restore_database}-${local.restore_backup_timestamp}.owner" : ""
  restore_grants_filename      = local.restore_enabled ? "${local.restore_database}-${local.restore_backup_timestamp}.grants.sql" : ""
  restore_backup_relative_path = local.restore_enabled ? "${local.backup_path}/databases/${local.restore_database}/${local.restore_backup_filename}" : ""
  restore_owner_relative_path  = local.restore_enabled ? "${local.backup_path}/databases/${local.restore_database}/${local.restore_owner_filename}" : ""
  restore_grants_relative_path = local.restore_enabled ? "${local.backup_path}/databases/${local.restore_database}/${local.restore_grants_filename}" : ""
  restore_backup_object = local.restore_enabled ? (
    local.backup_cli == "mc" ?
    "${local.backup_minio_alias}/${local.backup_bucket}/${local.restore_backup_relative_path}" :
    "s3://${local.backup_bucket}/${local.restore_backup_relative_path}"
  ) : ""
  restore_owner_object = local.restore_enabled ? (
    local.backup_cli == "mc" ?
    "${local.backup_minio_alias}/${local.backup_bucket}/${local.restore_owner_relative_path}" :
    "s3://${local.backup_bucket}/${local.restore_owner_relative_path}"
  ) : ""
  restore_grants_object = local.restore_enabled ? (
    local.backup_cli == "mc" ?
    "${local.backup_minio_alias}/${local.backup_bucket}/${local.restore_grants_relative_path}" :
    "s3://${local.backup_bucket}/${local.restore_grants_relative_path}"
  ) : ""
  restore_job_revision = "v1"
  restore_job_suffix = local.restore_enabled ? substr(sha1(join(":", [
    local.restore_backup_relative_path,
    local.restore_owner_relative_path,
    local.restore_grants_relative_path,
    local.restore_job_revision,
    local.backup_cli,
    local.backup_image,
    local.backup_tag,
  ])), 0, 8) : ""
  restore_job_name_prefix = local.restore_job_name_override != "" ? substr(lower(local.restore_job_name_override), 0, 54) : "${substr(local.cluster_name, 0, 18)}-${substr(lower(local.restore_database), 0, 18)}-restore"
  restore_job_name        = local.restore_enabled ? "${local.restore_job_name_prefix}-${local.restore_job_suffix}" : ""
}
