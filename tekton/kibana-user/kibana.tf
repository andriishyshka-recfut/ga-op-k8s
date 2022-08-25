
locals {
  dataEs = yamldecode(file("kibanas_settings.yaml"))
}

module "elastic7-kibana-1" {
  source                       = "../../terraform-modules/k8s-vault-kibana-lb"
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
  source                       = "../../terraform-modules/k8s-vault-kibana-lb"
  ElasticSettings              = local.dataEs.kibana2_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  # depends_on = [
  #   module.es7-restore
  # ]
}

module "elastic7-kibana-3" {
  source                       = "../../terraform-modules/k8s-vault-kibana-lb"
  ElasticSettings              = local.dataEs.kibana3_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  # depends_on = [
  #   module.es7-restore
  # ]
}
