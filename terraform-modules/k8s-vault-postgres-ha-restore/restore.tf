resource "kubernetes_manifest" "database_restore_job" {
  count = local.restore_enabled ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/database-restore-job.yaml.tftpl", {
    namespace                = local.namespace
    job_name                 = local.restore_job_name
    image                    = local.backup_image
    tag                      = local.backup_tag
    host                     = local.backup_host
    port                     = local.backup_port
    root_secret_name         = local.root_secret_name
    backup_secret_name       = local.backup_secret_name
    backup_minio_endpoint    = local.backup_minio_endpoint
    backup_cli               = local.backup_cli
    backup_mc_env            = local.backup_mc_env
    backup_mc_host           = local.backup_mc_host
    restore_database         = local.restore_database
    restore_backup_timestamp = local.restore_backup_timestamp
    restore_backup_object    = local.restore_backup_object
    restore_owner_object     = local.restore_owner_object
    restore_grants_object    = local.restore_grants_object
  }))

}
