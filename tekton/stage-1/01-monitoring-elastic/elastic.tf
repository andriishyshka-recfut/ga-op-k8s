locals {
  monitoringEs = var.Cluster == "production" ? yamldecode(file("./monitoring_elastic_settings.yaml")) : yamldecode(file("./monitoring_elastic_sandbox.yaml"))
}


module "monitoring-elastic" {
  source                       = "../../../terraform-modules/k8s-vault-monitoring-elastic"
  ElasticSettings              = local.monitoringEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  StoreEsPasswordInVault       = var.Cluster == "production" ? true : false
  BackupBucketName             = "backup"
  BackupBucketBasePath         = "es-backup/monitoring"
  OidcRedirectUri              = var.Settings.MonElasticFQDN
}
