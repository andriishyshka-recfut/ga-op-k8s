module "elastic8" {
  source                 = "../../terraform-modules/k8s-vault-elastic-helm"
  ElasticSettings        = yamldecode(file("${path.module}/elastic_settings.yaml")).ElasticSettings
  Cluster                = var.Cluster
  Color                  = var.Color
  Settings               = var.Settings
  StoreEsPasswordInVault = true
  MinioAddress           = var.Settings.clusters[var.Cluster].MinioAddress
  BackupBucketName       = "elasticsearch-backups"
  BackupBucketBasePath   = "8"
  OidcRedirectUri        = "k8.t.regemini.io"
  VaultAddress           = var.VaultAddress
}


module "kibana8" {
  source          = "../../terraform-modules/k8s-vault-kibana-helm"
  ElasticSettings = yamldecode(file("${path.module}/elastic_settings.yaml")).ElasticSettings
  KibanaSettings  = local.Kibana8Settings
  Cluster         = var.Cluster
  Color           = var.Color
  Settings        = var.Settings
  depends_on = [
    module.elastic8
  ]
}

module "logstash8" {
  source           = "../../terraform-modules/k8s-vault-logstash-pipelines"
  logstash_list    = var.Settings.clusters[var.Cluster][var.Color].logstash8
  logstash_version = var.Settings.clusters[var.Cluster].versions.logstash8.logstash_version
  Cluster          = var.Cluster
  Color            = var.Color
  Settings         = var.Settings
  depends_on = [ module.kibana8 ]
}