locals {
  monitoringEs = yamldecode(file("../01-monitoring/monitoring_elastic_settings.yaml"))
}


# module "monitoring-elastic" {
#   source                       = "../../terraform-modules/k8s-vault-elasticsearch"
#   ElasticSettings              = local.monitoringEs.elastic_settings
#   GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
#   Cluster                      = var.Cluster
#   Color                        = var.Color
#   Settings                     = var.Settings
#   StoreEsPasswordInVault       = false
# }
