#
# locals {
#   dataEs6 = yamldecode(file("elastic6_settings.yaml"))
# }
#
#
# module "data-elastic" {
#   source                       = "../../terraform-modules/k8s-vault-elastic"
#   ElasticSettings              = local.dataEs6.elastic_settings
#   GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
#   Cluster                      = var.Cluster
#   Color                        = var.Color
#   Settings                     = var.Settings
#   StoreEsPasswordInVault       = true
#   BackupBucketName             = "xbackup"
#   BackupBucketBasePath         = "es/elastic/"
#   OidcRedirectUri              = var.Settings.MonElasticFQDN
# }
#
#
# module "data-kibana" {
#   source                       = "../../terraform-modules/k8s-vault-kibana"
#   ElasticSettings              = local.dataEs6.elastic_settings
#   GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
#   Cluster                      = var.Cluster
#   Color                        = var.Color
#   Settings                     = var.Settings
#   depends_on                   = [module.es6-restore]
# }
