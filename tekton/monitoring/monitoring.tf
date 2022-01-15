
locals {
  monitoringEs = yamldecode(file("monitoring_elastic_settings.yaml"))
}


module "monitoring-elastic" {
  source                       = "../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.monitoringEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                      = var.Color
  Settings                     = var.Settings
  StoreEsPasswordInVault       = false
}

module "restore-service-indexes" {
  source                       = "../../terraform-modules/k8s-es-curator"
  Namespace = local.monitoringEs.elastic_settings.elastic.namespace
  ElasticName = local.monitoringEs.elastic_settings.elastic.esName
  NamePrefix = "restore-service-indexes"
  Actions = file("${path.root}/actions.yaml")
  depends_on          = [module.monitoring-elastic]
}

module "monitoring-kibana" {
  source                       = "../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.monitoringEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                      = var.Color
  Settings                     = var.Settings
  depends_on          = [module.restore-service-indexes]
}

module "monitoring-agents" {
  source     = "../../terraform-modules/k8s-vault-monitoring-agents"
  Cluster                      = var.Cluster
  Color                      = var.Color
  Settings                     = var.Settings
  depends_on          = [module.monitoring-kibana]
}

module "prometheus" {
  source              = "../../terraform-modules/k8s-vault-prometheus"
  OidcSecretVaultPath = "secret/oidc_google_prod"
  Settings            = var.Settings
  Cluster             = var.Cluster
  Color               =  var.Color
  depends_on          = [module.monitoring-elastic]
}
