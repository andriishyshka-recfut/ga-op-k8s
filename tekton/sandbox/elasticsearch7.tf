
locals {
  dataEs = yamldecode(file("elastic7_settings.yaml"))
}


module "elastic7-elastic" {
  source                       = "../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.dataEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  StoreEsPasswordInVault       = true
}


module "elastic7-kibana" {
  source                       = "../../terraform-modules/k8s-vault-kibana"
  ElasticSettings              = local.dataEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  # depends_on          = [module.restore-service-indexes]
}
