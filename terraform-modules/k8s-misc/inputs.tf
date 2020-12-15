
// k8s connection settings
variable "gke_cluster_connection_settings" {}

// Cluster variables and settings from common-vars module
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  gke_cluster_endpoint       = var.gke_cluster_connection_settings.HOST
  gke_bearer_token           = var.gke_cluster_connection_settings.API_KEY
  create_letsencrypt_issuers = lookup(var.Settings.clusters[var.Cluster][var.Color].cert_manager,"create_letsencrypt_issuers",false) ? 1 : 0
  ansible_envs = merge(var.gke_cluster_connection_settings, {
    CLUSTER_SETTINGS        = jsonencode(var.Settings)
    CLUSTER                 = var.Cluster
    COLOR                   = var.Color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.Settings.bastion_dns
  })

  eck_version = var.Settings.clusters[var.Cluster][var.Color].eck_version
}
