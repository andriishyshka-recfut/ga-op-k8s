variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "DoRestoreFromBackup" {
  default = false
}
variable "GkeClusterConnectionSettings" {}


locals {
  harborNs        = "harbor"
  harborVersion   = var.Settings.clusters[var.Cluster].versions.harbor.version
  restoreSwitcher = var.DoRestoreFromBackup ? 1 : 0
  gkeClusterEndpoint      = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken          = var.GkeClusterConnectionSettings.API_KEY
  harborValues = {
    harborAdminPassword = data.vault_generic_secret.harbor_passwords_secret.data.harborAdminPassword
    dbIntPassword = data.vault_generic_secret.harbor_passwords_secret.data.harborDatabasePassword
    dbExtPassword = data.vault_generic_secret.harbor_passwords_secret.data.harborDatabasePassword
    regUsername = data.vault_generic_secret.harbor_passwords_secret.data.harborRegistryUser
    regPassword = data.vault_generic_secret.harbor_passwords_secret.data.harborRegistryPassword
    s3Accesskey = jsondecode(data.vault_generic_secret.minio_auth.data.harbor).accessKey
    s3Secretkey = jsondecode(data.vault_generic_secret.minio_auth.data.harbor).secretKey
  }
}
