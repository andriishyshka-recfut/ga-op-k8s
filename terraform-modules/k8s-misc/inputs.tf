
// k8s connection settings
variable "gke_cluster_connection_settings" {}

// Cluster variables and settings from common-vars module
variable "settings" {}
variable "cluster" {}
variable "color" {}

locals {
  gke_cluster_endpoint       = var.gke_cluster_connection_settings.HOST
  gke_bearer_token           = var.gke_cluster_connection_settings.API_KEY
  create_letsencrypt_issuers = var.settings.clusters[var.cluster][var.color].cert_manager.create_letsencrypt_issuers ? 1 : 0
  ansible_envs = merge(var.gke_cluster_connection_settings, {
    CLUSTER_SETTINGS        = jsonencode(var.settings)
    CLUSTER                 = var.cluster
    COLOR                   = var.color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.settings.bastion_dns
  })
}
