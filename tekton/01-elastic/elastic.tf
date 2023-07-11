
module "elastic" {
  source                 = "../../terraform-modules/k8s-vault-elastic-helm"
  ElasticSettings        = local.ElasticSettings
  Cluster                = var.Cluster
  Color                  = var.Color
  Settings               = var.Settings
  StoreEsPasswordInVault = true
  MinioAddress           = var.Settings.clusters[var.Cluster].MinioAddress
  BackupBucketName       = "es7"
  BackupBucketBasePath   = "7"
  OidcRedirectUri        = "k.regemini.com"
}

module "kibana" {
  source          = "../../terraform-modules/k8s-vault-kibana-helm"
  ElasticSettings = local.ElasticSettings
  KibanaSettings  = local.KibanaSettings
  Cluster         = var.Cluster
  Color           = var.Color
  Settings        = var.Settings
}

module "beats" {
  source             = "../../terraform-modules/k8s-vault-elastic-beats-helm"
  ElasticSettings    = local.ElasticSettings
  BeatKibanaService  = "kb-ga"
  BeatElasticService = "red-coor.elastic.svc"
  logstash_pipelines = true
}
