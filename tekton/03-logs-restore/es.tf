


# module "backup" {
#   source               = "../../terraform-modules/k8s-es-curator"
#   Namespace            = "monitoring"
#   ElasticName          = "monitoring"
#   NamePrefix           = "backup"
#   BackupBucketName     = "xbackup"
#   BackupBucketBasePath = "es-backup/monitoring"
#   MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
#   Actions              = file("${path.root}/es-backup-actions.yaml")
#   Settings             = var.Settings
#   providers = {
#     kubernetes = kubernetes.kubernetes-inactive
#   }
# }

module "restore" {
  source               = "../../terraform-modules/k8s-es-curator"
  Namespace            = "monitoring"
  ElasticName          = "monitoring"
  NamePrefix           = "restore-logs"
  BackupBucketName     = "xbackup"
  BackupBucketBasePath = "es-backup/monitoring"
  MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
  Actions              = file("${path.root}/es-restore-actions.yaml")
  Settings             = var.Settings
  # depends_on           = [module.backup]
}
