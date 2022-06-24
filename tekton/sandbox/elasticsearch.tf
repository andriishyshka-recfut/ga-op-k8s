
locals {
  dataEs7 = yamldecode(file("data_elastic_settings.yaml"))
}


module "data-elastic" {
  source                       = "../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.dataEs7.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  StoreEsPasswordInVault       = true
  BackupBucketName             = "xbackup"
  BackupBucketBasepath         = "es/elastic/"
  OidcRedirectUri              = var.Settings.MonElasticFQDN
}


module "data-kibana" {
  source                       = "../../terraform-modules/k8s-vault-kibana"
  ElasticSettings              = local.dataEs7.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  # depends_on          = [module.restore-service-indexes]
}
