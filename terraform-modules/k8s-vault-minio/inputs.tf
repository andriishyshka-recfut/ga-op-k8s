variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  minioNs                   = "minio2"
  minioServiceAccountId     = var.Settings.clusters[var.Cluster].persistent_resources.minio_service_account_id
  vaultUsersCredentialsPath = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/users"
  vaultRootCredentialsPath  = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/root"
  vaultOidcConfigPath       = var.Settings.clusters[var.Cluster][var.Color].minio.vault_oidc_config_path
  minioFqdn                 = var.Settings.clusters[var.Cluster][var.Color].minio.fqdn
  currentProject  = var.Settings.gcpProject
  imageTag = var.Settings.clusters[var.Cluster][var.Color].minio.image_tag
  mcImageTag = var.Settings.clusters[var.Cluster][var.Color].minio.mc_image_tag
}
