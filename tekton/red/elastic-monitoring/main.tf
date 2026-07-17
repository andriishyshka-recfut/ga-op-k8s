locals {
  ElasticSettings = yamldecode(file("${path.module}/elastic_settings.yaml")).ElasticSettings
}

module "elastic-monitoring" {
  source                 = "../../../terraform-modules/k8s-vault-elastic-helm"
  ElasticSettings        = local.ElasticSettings
  Cluster                = var.Cluster
  Color                  = var.Color
  Settings               = var.Settings
  StoreEsPasswordInVault = true
  MinioAddress           = var.Settings.clusters[var.Cluster].MinioAddress
  BackupBucketName       = "backup"
  BackupBucketBasePath   = "es-backup/monitoring"
  OidcRedirectUri        = var.Settings.MonElasticFQDN
  VaultAddress           = var.VaultAddress
}