
# module "backup-old-indexes" {
#   source               = "../../../terraform-modules/k8s-es-curator"
#   Namespace            = "monitoring"
#   ElasticName          = "monitoring"
#   NamePrefix           = "backup-old-indexes"
#   BackupBucketName     = "backup"
#   BackupBucketBasePath = "es-backup/monitoring"
#   EsService            = "mon-es-http"
#   EsCreds              = "mon-es-elastic-user"
#   MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
#   Actions              = file("${path.root}/es-backup-actions.yaml")
#   Settings             = var.Settings
#   providers = {
#     kubernetes = kubernetes.kubernetes-inactive
#   }
# }


# module "restore-old-indexes" {
#   source               = "../../../terraform-modules/k8s-es-curator"
#   Namespace            = "monitoring"
#   ElasticName          = "monitoring"
#   NamePrefix           = "restore-old-indexes"
#   BackupBucketName     = "backup"
#   BackupBucketBasePath = "es-backup/monitoring"
#   EsService            = "mon-es-http"
#   EsCreds              = "mon-es-elastic-user"
#   MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
#   Actions              = file("${path.root}/es-restore-actions.yaml")
#   Settings             = var.Settings
#   depends_on           = [module.backup-old-indexes]
# }
