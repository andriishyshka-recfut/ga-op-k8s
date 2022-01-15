
locals{
  dataEs                 = yamldecode(file("data_elastic_settings.yaml"))
}


module "data-elastic" {
  source                       = "../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.dataEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  StoreEsPasswordInVault       = true
}

module "restore-service-indexes" {
  source                       = "../../terraform-modules/k8s-es-curator"
  Namespace = local.dataEs.elastic_settings.elastic.namespace
  ElasticName = local.dataEs.elastic_settings.elastic.esName
  NamePrefix = "restore-service-indexes"
  Actions = file("${path.root}/actions.yaml")
  depends_on          = [module.data-elastic]
}

module "data-kibana" {
  source                       = "../../terraform-modules/k8s-vault-kibana"
  ElasticSettings              = local.dataEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                      = var.Color
  Settings                     = var.Settings
  depends_on          = [module.restore-service-indexes]
}
