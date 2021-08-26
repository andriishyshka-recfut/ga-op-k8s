
locals {
  monitoringEs = yamldecode(file("monitoring_elastic_settings.yaml"))
}


module "monitoring-elastic" {
  source                       = "../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.monitoringEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                      = local.activeCluster
  Settings                     = var.Settings
  StoreEsPasswordInVault       = false
}

module "monitoring-agents" {
  source     = "../../terraform-modules/k8s-vault-monitoring-agents"
  Cluster                      = var.Cluster
  Color                      = local.activeCluster
  Settings                     = var.Settings
  depends_on          = [module.monitoring-elastic]
}

module "prometheus" {
  source              = "../../terraform-modules/k8s-vault-prometheus"
  OidcSecretVaultPath = "secret/oidc_google_prod"
  Settings            = var.Settings
  Cluster             = var.Cluster
  Color               = local.activeCluster
  depends_on          = [module.monitoring-elastic]
}
