
module "elastic" {
  source                 = "../../../terraform-modules/k8s-vault-elastic-helm"
  ElasticSettings        = local.ElasticSettings
  Cluster                = var.Cluster
  Color                  = var.Color
  Settings               = var.Settings
  StoreEsPasswordInVault = true
  MinioAddress           = var.Settings.clusters[var.Cluster].MinioAddress
  BackupBucketName       = "es7"
  BackupBucketBasePath   = "7"
  OidcRedirectUri        = "k.regemini.com"
  VaultAddress           = var.VaultAddress
}

