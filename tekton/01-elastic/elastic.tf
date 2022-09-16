
locals {
  dataEs = yamldecode(file("elastic_settings.yaml"))
}


module "elastic-elastic" {
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
  OidcRedirectUri              = "kk.regemini.io"
}


# module "elastic-kibana" {
#   source                       = "../../terraform-modules/k8s-vault-kibana"
#   ElasticSettings              = local.dataEs.elastic_settings
#   GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
#   Cluster                      = var.Cluster
#   Color                        = var.Color
#   Settings                     = var.Settings
#   # depends_on          = [module.restore-service-indexes]
# }

# module "elastic-beats" {
#   source   = "../../terraform-modules/k8s-vault-elastic-beats"
#   Cluster  = var.Cluster
#   Color    = var.Color
#   Settings = var.Settings
#   # depends_on = [module.elastic-kibana]
# }
