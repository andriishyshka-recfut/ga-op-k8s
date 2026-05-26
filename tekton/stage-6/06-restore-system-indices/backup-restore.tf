locals {
  monitoringEs = var.Cluster == "production" ? yamldecode(file("../../stage-1/01-monitoring-elastic/monitoring_elastic_settings.yaml")) : yamldecode(file("../../stage-1/01-monitoring-elastic/monitoring_elastic_sandbox.yaml"))
}

module "backup-system-indexes" {
  source               = "../../../terraform-modules/k8s-es-curator"
  Namespace            = local.monitoringEs.elastic_settings.elastic.namespace
  ElasticName          = local.monitoringEs.elastic_settings.elastic.esName
  NamePrefix           = "backup-system-indexes"
  BackupBucketName     = "backup"
  BackupBucketBasePath = "es-backup/monitoring"
  EsService            = "mon-es-http"
  EsCreds              = "mon-es-elastic-user"
  MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
  Actions              = file("${path.root}/backup-system.yaml")
  Settings             = var.Settings
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}

module "backup-lfb-indexes" {
  source               = "../../../terraform-modules/k8s-es-curator"
  Namespace            = local.monitoringEs.elastic_settings.elastic.namespace
  ElasticName          = local.monitoringEs.elastic_settings.elastic.esName
  NamePrefix           = "backup-lfb-indexes"
  BackupBucketName     = "backup"
  BackupBucketBasePath = "es-backup/monitoring"
  EsService            = "mon-es-http"
  EsCreds              = "mon-es-elastic-user"
  MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
  Actions              = file("${path.root}/backup-lfb.yaml")
  Settings             = var.Settings
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
  depends_on = [module.backup-system-indexes]
}


module "restore-system-indexes" {
  source               = "../../../terraform-modules/k8s-es-curator"
  Namespace            = local.monitoringEs.elastic_settings.elastic.namespace
  ElasticName          = local.monitoringEs.elastic_settings.elastic.esName
  NamePrefix           = "restore-system-indexes"
  BackupBucketName     = "backup"
  BackupBucketBasePath = "es-backup/monitoring"
  EsService            = "mon-es-http"
  EsCreds              = "mon-es-elastic-user"
  MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
  Actions              = file("${path.root}/restore-system.yaml")
  Settings             = var.Settings
  depends_on           = [module.backup-lfb-indexes]
}
module "restore-lfb-indexes" {
  source               = "../../../terraform-modules/k8s-es-curator"
  Namespace            = local.monitoringEs.elastic_settings.elastic.namespace
  ElasticName          = local.monitoringEs.elastic_settings.elastic.esName
  NamePrefix           = "restore-lfb-indexes"
  BackupBucketName     = "backup"
  BackupBucketBasePath = "es-backup/monitoring"
  EsService            = "mon-es-http"
  EsCreds              = "mon-es-elastic-user"
  MinioAddress         = var.Settings.clusters[var.Cluster].MinioAddress
  Actions              = file("${path.root}/restore-lfb.yaml")
  Settings             = var.Settings
  depends_on           = [module.restore-system-indexes]
}
