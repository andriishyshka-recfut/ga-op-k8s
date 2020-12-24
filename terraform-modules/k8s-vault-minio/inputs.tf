variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  minioNs                   = "minio"
  minioServiceAccountId     = var.Settings.clusters[var.Cluster].persistent_resources.minio_service_account_id
  vaultUsersCredentialsPath = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/users"
  vaultRootCredentialsPath  = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/root"

}
