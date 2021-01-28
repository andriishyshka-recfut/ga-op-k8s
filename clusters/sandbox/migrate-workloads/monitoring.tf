



module "monitoring-elastic" {
  source                       = "../../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.monitoringEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = "sandbox"
  Settings                     = var.Settings
  StoreEsPasswordInVault       = false
  depends_on                   = [module.namespaces]
}

module "monitoring-agents" {
  source     = "../../../terraform-modules/k8s-vault-monitoring-agents"
  depends_on = [module.monitoring-elastic]
}
