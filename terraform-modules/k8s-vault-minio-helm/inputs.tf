variable "GkeClusterConnectionSettings" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  minioNs = "minio-helm"
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
  })

  vaultUsersCredentialsPath = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/users"
  vaultRootCredentialsPath  = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/root"
  vaultOidcConfigPath       = var.Settings.clusters[var.Cluster][var.Color].minio.vault_oidc_config_path
  minioFqdn                 = var.Cluster == "production" ? "minio-helm.p.regemini.io" : "minio-helm.t.regemini.io"
  vaultFqdn                 = var.Cluster == "production" ? "vault.p.regemini.io" : "vault.t.regemini.io"
  minioConsoleFqdn          = var.Settings.clusters[var.Cluster][var.Color].minio.console_fqdn
  currentProject            = var.Settings.gcpProject
  imageTag                  = var.Settings.clusters[var.Cluster][var.Color].minio.image_tag
  mcImageTag                = "RELEASE.2023-09-13T23-08-58Z"
  replicas                  = var.Settings.clusters[var.Cluster][var.Color].minio.replicas
  pv_disk_count             = 0
  diskSize                  = "20Gi"
}
