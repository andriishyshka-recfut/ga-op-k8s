variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


data "google_client_config" "current" {}
locals {
  minioNs                   = "minio"
  minioServiceAccountId     = var.Settings.clusters[var.Cluster].persistent_resources.minio_service_account_id
  vaultUsersCredentialsPath = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/users"
  vaultRootCredentialsPath  = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/root"
  vaultOidcConfigPath       = var.Settings.clusters[var.Cluster][var.Color].minio.vault_oidc_config_path
  minioFqdn                 = var.Settings.clusters[var.Cluster][var.Color].minio.fqdn
  currentProject  = data.google_client_config.current.project
  imageTag = var.Settings.clusters[var.Cluster][var.Color].minio.image_tag
  mcImageTag = var.Settings.clusters[var.Cluster][var.Color].minio.mc_image_tag
}
