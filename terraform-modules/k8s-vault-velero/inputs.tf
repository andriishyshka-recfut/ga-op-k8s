
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  veleroNs                 = "velero"
  vaultRootCredentialsPath = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/root"
}
