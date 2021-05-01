
locals{
  monitoringEs           = yamldecode(file("monitoring_elastic_settings.yaml"))
}


module "monitoring-elastic" {
  source                       = "../../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.monitoringEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Settings                     = var.Settings
  StoreEsPasswordInVault       = false
  depends_on                   = [module.namespaces,module.minio]
}

module "monitoring-agents" {
  source     = "../../../terraform-modules/k8s-vault-monitoring-agents"
  depends_on = [module.monitoring-elastic]
}

module "prometheus" {
  source   = "../../../terraform-modules/k8s-vault-prometheus"
  OidcSecretVaultPath = "secret/oidc_google_test"
  depends_on = [module.monitoring-elastic]
}
