# locals {
#   monitoringEs = yamldecode(file("../../stage-1/01-monitoring/monitoring_elastic_settings.yaml"))
# }

# module "backup-service" {
#   source               = "../../../terraform-modules/k8s-es-curator"
#   Namespace            = local.monitoringEs.elastic_settings.elastic.namespace
#   ElasticName          = local.monitoringEs.elastic_settings.elastic.esName
#   NamePrefix           = "backup-service-indexes"
#   BackupBucketName     = "xbackup"
#   BackupBucketBasePath = "es-backup/monitoring"
#   EsService            = "mon-es-http"
#   EsCreds              = "mon-es-elastic-user"
#   MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
#   Actions              = file("${path.root}/backup-actions.yaml")
#   Settings             = var.Settings
#   providers = {
#     kubernetes = kubernetes.kubernetes-inactive
#   }
# }

# module "backup-lfb" {
#   source               = "../../../terraform-modules/k8s-es-curator"
#   Namespace            = local.monitoringEs.elastic_settings.elastic.namespace
#   ElasticName          = local.monitoringEs.elastic_settings.elastic.esName
#   NamePrefix           = "backup-service-indexes"
#   BackupBucketName     = "xbackup"
#   BackupBucketBasePath = "es-backup/monitoring"
#   EsService            = "mon-es-http"
#   EsCreds              = "mon-es-elastic-user"
#   MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
#   Actions              = file("${path.root}/backup-lfb.yaml")
#   Settings             = var.Settings
#   providers = {
#     kubernetes = kubernetes.kubernetes-inactive
#   }
#   depends_on = [module.backup-service]
# }

# module "restore-service-indexes" {
#   source               = "../../../terraform-modules/k8s-es-curator"
#   Namespace            = local.monitoringEs.elastic_settings.elastic.namespace
#   ElasticName          = local.monitoringEs.elastic_settings.elastic.esName
#   NamePrefix           = "restore-service-indexes"
#   BackupBucketName     = "xbackup"
#   BackupBucketBasePath = "es-backup/monitoring"
#   EsService            = "mon-es-http"
#   EsCreds              = "mon-es-elastic-user"
#   MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
#   Actions              = file("${path.root}/restore-actions.yaml")
#   Settings             = var.Settings
#   depends_on           = [module.backup-service]
# }
# module "restore-lfb-indexes" {
#   source               = "../../../terraform-modules/k8s-es-curator"
#   Namespace            = local.monitoringEs.elastic_settings.elastic.namespace
#   ElasticName          = local.monitoringEs.elastic_settings.elastic.esName
#   NamePrefix           = "restore-lfb-indexes"
#   BackupBucketName     = "xbackup"
#   BackupBucketBasePath = "es-backup/monitoring"
#   EsService            = "mon-es-http"
#   EsCreds              = "mon-es-elastic-user"
#   MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
#   Actions              = file("${path.root}/restore-lfb-action.yaml")
#   Settings             = var.Settings
#   depends_on           = [module.restore-service-indexes]
# }
