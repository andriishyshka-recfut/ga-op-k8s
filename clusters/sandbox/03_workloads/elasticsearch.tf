
locals{
  dataEs                 = yamldecode(file("data_elastic_settings.yaml"))
}


module "data-elastic" {
  source                       = "../../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.dataEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Settings                     = var.Settings
  StoreEsPasswordInVault       = true
  depends_on                   = [module.namespaces]
}
