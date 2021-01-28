
module "data-elastic" {
  source                       = "../../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.dataEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = "sandbox"
  Settings                     = var.Settings
  StoreEsPasswordInVault       = false
  depends_on                   = [module.namespaces]
}
