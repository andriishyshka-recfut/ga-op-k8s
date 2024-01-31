
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

  trial_licenses = var.Color == "red" ? 0 : 1
  eck_installs = var.Color == "red" ? 0 : 1
  eckVersion = var.Settings.clusters[var.Cluster][var.Color].versions.elasticsearch.eck_version
}
