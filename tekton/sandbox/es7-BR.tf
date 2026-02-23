
# module "es7-backup" {
#   source               = "../../terraform-modules/k8s-es-curator"
#   Namespace            = "elastic"
#   ElasticName          = "elastic"
#   NamePrefix           = "xbackup"
#   BackupBucketName     = "elasticsearch-backups"
#   BackupBucketBasePath = "7-new"
#   EsService            = "elasticsearch-coor"
#   EsCreds              = "elastic-credentials"
#   MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
#   Actions              = file("${path.root}/es7-backup-actions.yaml")
#   Settings             = var.Settings
#   providers = {
#     kubernetes = kubernetes.kubernetes-inactive
#   }
#   depends_on = [
#     module.elastic
#   ]
# }


# module "es7-restore-system" {
#   source               = "../../terraform-modules/k8s-es-curator"
#   Namespace            = "elastic"
#   ElasticName          = "elastic"
#   NamePrefix           = "restore-logs"
#   BackupBucketName     = "elasticsearch-backups"
#   BackupBucketBasePath = "7-new"
#   EsService            = "elasticsearch-coor"
#   EsCreds              = "elastic-credentials"
#   MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
#   Actions              = file("${path.root}/es7-restore-actions.yaml")
#   Settings             = var.Settings
#   depends_on = [
#     module.elastic,
#     module.es7-backup
#   ]
# }

# module "es7-restore-other" {
#   source               = "../../terraform-modules/k8s-es-curator"
#   Namespace            = "elastic"
#   ElasticName          = "elastic"
#   NamePrefix           = "restore-logs"
#   BackupBucketName     = "elasticsearch-backups"
#   BackupBucketBasePath = "7-new"
#   EsService            = "elasticsearch-coor"
#   EsCreds              = "elastic-credentials"
#   MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
#   Actions              = file("${path.root}/es7-restore-other.yaml")
#   Settings             = var.Settings
#   depends_on = [
#     module.es7-restore-system
#   ]
# }
