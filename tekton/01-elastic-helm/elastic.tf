
locals {
  dataKibana = yamldecode(file("kibanas_settings.yaml"))
}

module "elastic-elastic" {
  source                 = "../../terraform-modules/k8s-vault-elastic-helm"
  ElasticSettings        = local.elasticSettings
  Cluster                = var.Cluster
  Color                  = var.Color
  Settings               = var.Settings
  StoreEsPasswordInVault = true
  MinioAddress           = var.Settings.clusters[var.Cluster].MinioAddress
  BackupBucketName       = "es7"
  BackupBucketBasePath   = "7"
  OidcRedirectUri        = "k.regemini.com"
}

# module "kibana-1" {
#   source                       = "../../terraform-modules/k8s-vault-kibana-lb"
#   ElasticSettings              = local.dataKibana.kibana1_settings
#   GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
#   Cluster                      = var.Cluster
#   Color                        = var.Color
#   Settings                     = var.Settings
# }

# module "kibana-2" {
#   source                       = "../../terraform-modules/k8s-vault-kibana-lb"
#   ElasticSettings              = local.dataKibana.kibana2_settings
#   GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
#   Cluster                      = var.Cluster
#   Color                        = var.Color
#   Settings                     = var.Settings
# }

# module "kibana-3" {
#   source                       = "../../terraform-modules/k8s-vault-kibana-lb"
#   ElasticSettings              = local.dataKibana.kibana3_settings
#   GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
#   Cluster                      = var.Cluster
#   Color                        = var.Color
#   Settings                     = var.Settings
# }

# module "elastic-beats" {
#   source     = "../../terraform-modules/k8s-vault-elastic-beats"
#   Cluster    = var.Cluster
#   Color      = var.Color
#   Settings   = var.Settings
#   depends_on = [module.elastic-elastic, module.kibana-1, module.kibana-2, module.kibana-3]
# }
