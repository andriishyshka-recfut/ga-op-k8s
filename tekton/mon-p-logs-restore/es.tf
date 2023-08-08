module "restore" {
  source               = "../../terraform-modules/k8s-es-curator"
  Namespace            = "monitoring"
  ElasticName          = "monitoring"
  NamePrefix           = "restore-logs"
  BackupBucketName     = "xbackup"
  BackupBucketBasePath = "es-backup/monitoring"
  EsService            = "monitoring-es-http"
  EsCreds              = "monitoring-es-elastic-user"
  MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
  Actions              = file("${path.root}/es-restore-actions.yaml")
  Settings             = var.Settings
}
