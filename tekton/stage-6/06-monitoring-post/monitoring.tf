
locals {
  monitoringEs = yamldecode(file("../../stage-1/01-monitoring/monitoring_elastic_settings.yaml"))
}

module "monitoring-kibana" {
  source                       = "../../../terraform-modules/k8s-vault-kibana"
  ElasticSettings              = local.monitoringEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
}

module "monitoring-agents" {
  source     = "../../../terraform-modules/k8s-vault-monitoring-agents"
  Cluster    = var.Cluster
  Color      = var.Color
  Settings   = var.Settings
  depends_on = [module.monitoring-kibana]
}

module "prometheus-addons" {
  source              = "../../../terraform-modules/k8s-vault-prometheus-addons-post"
  OidcSecretVaultPath = "secret/oidc_google_prod"
  Settings            = var.Settings
  Cluster             = var.Cluster
  Color               = var.Color
}
