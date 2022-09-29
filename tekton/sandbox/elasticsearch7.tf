
locals {
  dataEs = yamldecode(file("elastic7_settings.yaml"))
}


module "elastic7-elastic" {
  source                       = "../../terraform-modules/k8s-vault-elastic"
  ElasticSettings              = local.dataEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  StoreEsPasswordInVault       = true
  MinioAddress                 = var.Settings.clusters[var.Cluster].MinioAddress
  BackupBucketName             = "es7"
  BackupBucketBasePath         = "7"
  OidcRedirectUri              = "k.t.regemini.io"
}


module "elastic7-kibana" {
  source                       = "../../terraform-modules/k8s-vault-kibana"
  ElasticSettings              = local.dataEs.kibana1_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  # depends_on = [
  #   module.es7-restore
  # ]
}

module "elastic7-kibana-2" {
  source                       = "../../terraform-modules/k8s-vault-kibana"
  ElasticSettings              = local.dataEs.kibana2_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  # depends_on = [
  #   module.es7-restore
  # ]
}