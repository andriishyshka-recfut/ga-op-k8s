module "restore_system_indices" {
  source               = "../../terraform-modules/k8s-es-curator"
  Namespace            = "monitoring"
  ElasticName          = "monitoring"
  NamePrefix           = "restore-logs"
  BackupBucketName     = "xbackup"
  BackupBucketBasePath = "es-backup/monitoring"
  EsService            = "monitoring-es-http"
  EsCreds              = "monitoring-es-elastic-user"
  MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
  Actions              = file("${path.root}/es-restore-system-indices.yaml")
  Settings             = var.Settings
}

module "restore_latest_filebeat" {
  source               = "../../terraform-modules/k8s-es-curator"
  Namespace            = "monitoring"
  ElasticName          = "monitoring"
  NamePrefix           = "restore-logs"
  BackupBucketName     = "xbackup"
  BackupBucketBasePath = "es-backup/monitoring"
  EsService            = "monitoring-es-http"
  EsCreds              = "monitoring-es-elastic-user"
  MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
  Actions              = file("${path.root}/es-restore-latest-filebeat.yaml")
  Settings             = var.Settings
  depends_on = [ module.restore_system_indices ]
}


module "restore_old_filebeats" {
  source               = "../../terraform-modules/k8s-es-curator"
  Namespace            = "monitoring"
  ElasticName          = "monitoring"
  NamePrefix           = "restore-logs"
  BackupBucketName     = "xbackup"
  BackupBucketBasePath = "es-backup/monitoring"
  EsService            = "monitoring-es-http"
  EsCreds              = "monitoring-es-elastic-user"
  MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
  Actions              = file("${path.root}/es-restore-old-filebeats.yaml")
  Settings             = var.Settings
  depends_on = [ module.restore_latest_filebeat ]
}
