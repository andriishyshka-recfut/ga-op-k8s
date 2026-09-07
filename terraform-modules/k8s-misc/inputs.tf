
variable "GkeClusterConnectionSettings" {}

variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  gkeClusterEndpoint      = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken          = var.GkeClusterConnectionSettings.API_KEY
  letsEncryptIssuersCount = lookup(var.Settings.clusters[var.Cluster][var.Color].cert_manager, "create_letsencrypt_issuers", false) ? 1 : 0
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    CLUSTER_SETTINGS        = jsonencode(var.Settings)
    CLUSTER                 = var.Cluster
    COLOR                   = var.Color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.Settings.bastion_dns
  })
  artifactoryUrl        = "repo-external.recfut.com"
  enableArtifactoryMtls = lookup(var.Settings, "enableArtifactoryMtls", false) != false ? 1 : 0
  dateNow               = formatdate("YYYYMMDD", timestamp())
  cert_manager_issuers = templatefile(
    "${path.module}/cert-manager-issuers.tftpl",{ istio = var.Settings.clusters[var.Cluster][var.Color].istio })
}
