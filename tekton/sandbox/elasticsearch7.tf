
module "elastic" {
  source                 = "../../terraform-modules/k8s-vault-elastic-helm"
  ElasticSettings        = local.ElasticSettings
  Cluster                = var.Cluster
  Color                  = var.Color
  Settings               = var.Settings
  StoreEsPasswordInVault = true
  MinioAddress           = var.Settings.clusters[var.Cluster].MinioAddress
  BackupBucketName       = "elasticsearch-backups"
  BackupBucketBasePath   = "7-new"
  OidcRedirectUri        = "k.t.regemini.io"
}


module "kibana" {
  source          = "../../terraform-modules/k8s-vault-kibana-helm"
  ElasticSettings = local.ElasticSettings
  KibanaSettings  = local.KibanaSettings
  Cluster         = var.Cluster
  Color           = var.Color
  Settings        = var.Settings
  depends_on = [
    module.es7-restore-system
  ]
}
