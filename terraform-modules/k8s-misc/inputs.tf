
// k8s connection settings
variable "gke_cluster_connection_settings" {}

// Cluster variables and settings from common-vars module
variable "settings" {}
variable "cluster" {}
variable "color" {}

locals {
  gke_cluster_endpoint       = var.gke_cluster_connection_settings.gke_cluster_endpoint
  gke_bearer_token           = var.gke_cluster_connection_settings.gke_bearer_token
  create_letsencrypt_issuers = var.settings.clusters[var.cluster][var.color].cert_manager.create_letsencrypt_issuers ? 1 : 0
  ansible_envs = {
    CLUSTER_SETTINGS        = jsonencode(var.settings)
    CLUSTER                 = var.cluster
    COLOR                   = var.color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    HOST                    = var.gke_cluster_connection_settings.gke_cluster_endpoint
    API_KEY                 = var.gke_cluster_connection_settings.gke_bearer_token
    CLUSTER_CA_CERTIFICATE  = var.gke_cluster_connection_settings.cluster_ca_certificate
    BASTION_DNS             = var.settings.bastion_dns
  }
}
