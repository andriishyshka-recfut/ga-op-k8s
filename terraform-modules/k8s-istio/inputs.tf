

data "google_compute_instance" "bastion" {
  name = var.settings.bastion_hostname
  zone = var.settings.bastion_zone
}

// Upload temp key to be able run ansible
data "external" "data" {
  program = ["sh", "${path.module}/../../data.sh"]
}
// Service account and project info
data "google_client_openid_userinfo" "me" {
}
data "google_service_account" "me" {
  account_id = element(split("@", data.google_client_openid_userinfo.me.email), 0)
}

data "google_project" "project" {
}

// k8s connection settings
variable "gke_cluster_connection_settings" {}

// Cluster variables and settings from common-vars module
variable "settings" {}
variable "cluster" {}
variable "color" {}

# variable "vault_resources" {}


locals {
  bastion_expose_toggle = (
    lookup(var.settings.clusters[var.cluster][var.color].istio,"expose_istio_ingres_on_bastion", false ) &&
    lookup(var.settings.clusters[var.cluster][var.color], "active", false)
  ) ? 1 : 0


  # gke_cluster_endpoint   = var.gke_cluster_connection_settings.gke_cluster_endpoint
  # gke_bearer_token       = var.gke_cluster_connection_settings.gke_bearer_token
  # cluster_ca_certificate = var.gke_cluster_connection_settings.cluster_ca_certificate
  ansible_envs = merge(var.gke_cluster_connection_settings, {
    CLUSTER_SETTINGS        = jsonencode(var.settings)
    CLUSTER                 = var.cluster
    COLOR                   = var.color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.settings.bastion_dns
  })
}
