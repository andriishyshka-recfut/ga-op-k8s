variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  minioNs                   = "minio"

  vaultUsersCredentialsPath = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/users"
  vaultRootCredentialsPath  = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/root"
  vaultOidcConfigPath       = var.Settings.clusters[var.Cluster][var.Color].minio.vault_oidc_config_path
  minioFqdn                 = var.Settings.clusters[var.Cluster][var.Color].minio.fqdn
  minioConsoleFqdn                 = var.Settings.clusters[var.Cluster][var.Color].minio.console_fqdn
  currentProject  = var.Settings.gcpProject
  imageTag = var.Settings.clusters[var.Cluster][var.Color].minio.image_tag
  mcImageTag = var.Settings.clusters[var.Cluster][var.Color].minio.mc_image_tag
  replicas = var.Settings.clusters[var.Cluster][var.Color].minio.replicas
}
