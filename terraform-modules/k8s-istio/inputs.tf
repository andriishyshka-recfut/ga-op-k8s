

data "google_compute_instance" "bastion" {
  name = var.Settings.bastion_hostname
  zone = var.Settings.bastion_zone
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
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

# variable "vault_resources" {}


locals {
  bastion_expose_toggle = (
    lookup(var.Settings.clusters[var.Cluster][var.Color].istio,"expose_istio_ingres_on_bastion", false ) &&
    lookup(var.Settings.clusters[var.Cluster][var.Color], "active", false)
  ) ? 1 : 0


  # gke_cluster_endpoint   = var.gke_cluster_connection_settings.gke_cluster_endpoint
  # gke_bearer_token       = var.gke_cluster_connection_settings.gke_bearer_token
  # cluster_ca_certificate = var.gke_cluster_connection_settings.cluster_ca_certificate
  ansible_envs = merge(var.gke_cluster_connection_settings, {
    CLUSTER_SETTINGS        = jsonencode(var.Settings)
    CLUSTER                 = var.Cluster
    COLOR                   = var.Color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.Settings.bastion_dns
  })
}
