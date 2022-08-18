module "es7-backup" {
  source               = "../../terraform-modules/k8s-es-curator"
  Namespace            = "elastic7"
  ElasticName          = "elastic7"
  NamePrefix           = "backup"
  BackupBucketName     = "es7"
  BackupBucketBasePath = "7"
  Actions              = file("${path.root}/es7-backup-actions.yaml")
  Settings             = var.Settings
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
  depends_on = [
    module.elastic7-elastic
  ]
}

module "es7-restore" {
  source               = "../../terraform-modules/k8s-es-curator"
  Namespace            = "elastic7"
  ElasticName          = "elastic7"
  NamePrefix           = "restore-logs"
  BackupBucketName     = "es7"
  BackupBucketBasePath = "7"
  Actions              = file("${path.root}/es7-restore-actions.yaml")
  Settings             = var.Settings
  depends_on           = [module.es7-backup]
}
