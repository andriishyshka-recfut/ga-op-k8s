

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
// OIDC setup settings. Should be passed as env variables during execution
variable "oidc_discovery_url" { default = "SAMPLE" }
variable "oidc_client_id" { default = "SAMPLE" }
variable "oidc_client_secret" { default = "SAMPLE" }



locals {
  vaultBucketName          = var.Settings.clusters[var.Cluster].persistent_resources.vault_bucket_name
  vault_key_name           = var.Settings.clusters[var.Cluster].persistent_resources.vault_key_name
  es_backup_bucket         = var.Settings.clusters[var.Cluster].persistent_resources.es_backup_bucket
  vault_service_account_id = var.Settings.clusters[var.Cluster].persistent_resources.vault_service_account_id
  project                  = split("/", data.google_project.project.id)[1]

  vault_fqdn = var.Settings.clusters[var.Cluster][var.Color].vault.fqdn
  vault_addr = "http://vault.vault.svc"

  cluster    = var.Cluster
  connection = lookup(var.Settings.clusters[var.Cluster][var.Color].vault, "connection", "remote")


  gke_cluster_endpoint = var.gke_cluster_connection_settings.HOST
  ansible_envs = merge(var.gke_cluster_connection_settings, {
    CLUSTER_SETTINGS        = jsonencode(var.Settings)
    CLUSTER                 = var.Cluster
    COLOR                   = var.Color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.Settings.bastion_dns
    vault_addr              = "https://${local.vault_fqdn}"
  })

  // toggles
  do_initial_provisioning    = var.Settings.clusters[var.Cluster][var.Color].vault.do_initial_provisioning ? 1 : 0
  create_cert-manager_issuer = var.Settings.clusters[var.Cluster][var.Color].vault.create_cert-manager_issuer ? 1 : 0
  create_k8s_admin           = var.Settings.clusters[var.Cluster][var.Color].vault.create_k8s_admin ? 1 : 0
  istio_expose               = var.Settings.clusters[var.Cluster][var.Color].vault.istio_expose ? 1 : 0
}
