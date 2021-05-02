


locals {
  es = yamldecode(file("monitoring_elastic_settings.yaml"))
}


module "monitoring-elastic" {
  source                       = "../../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.es.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = "production"
  Settings                     = var.Settings
  StoreEsPasswordInVault       = false
  depends_on                   = [module.namespaces]
}

module "monitoring-agents" {
  source     = "../../../terraform-modules/k8s-vault-monitoring-agents"
  depends_on = [module.monitoring-elastic]
}

module "prometheus" {
  source   = "../../../terraform-modules/k8s-vault-prometheus"
  depends_on = [module.monitoring-elastic]
}
