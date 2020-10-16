
data "external" "root_ca" {
  program = ["python3", "${path.module}/../data-vault-ca.py"]
  query = {
    vault_addr = local.vault_addr
  }
  depends_on = [
    null_resource.ansible_vault_k8s_auth
  ]
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
// OIDC setup settings. Should be passed as env variables during execution
variable "oidc_discovery_url" { default = "SAMPLE" }
variable "oidc_client_id" { default = "SAMPLE" }
variable "oidc_client_secret" { default = "SAMPLE" }



locals {
  vault_bucket_name        = var.settings.clusters[var.cluster].persistent_resources.vault_bucket_name
  vault_key_name           = var.settings.clusters[var.cluster].persistent_resources.vault_key_name
  es_backup_bucket         = var.settings.clusters[var.cluster].persistent_resources.es_backup_bucket
  vault_service_account_id = var.settings.clusters[var.cluster].persistent_resources.vault_service_account_id
  project                  = split("/", data.google_project.project.id)[1]

  vault_fqdn = var.settings.clusters[var.cluster][var.color].vault.fqdn
  vault_addr = lookup(var.settings.clusters[var.cluster][var.color].vault, "connection", "remote") == "local" ? "http://vault.vault.svc" : "https://${local.vault_fqdn}"

  cluster    = var.cluster
  connection = lookup(var.settings.clusters[var.cluster][var.color].vault, "connection", "remote")


  gke_cluster_endpoint = var.gke_cluster_connection_settings.HOST
  ansible_envs = merge(var.gke_cluster_connection_settings, {
    CLUSTER_SETTINGS        = jsonencode(var.settings)
    CLUSTER                 = var.cluster
    COLOR                   = var.color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.settings.bastion_dns
    vault_addr              = "https://${local.vault_fqdn}"
  })

  // toggles
  do_initial_provisioning    = var.settings.clusters[var.cluster][var.color].vault.do_initial_provisioning ? 1 : 0
  create_cert-manager_issuer = var.settings.clusters[var.cluster][var.color].vault.create_cert-manager_issuer ? 1 : 0
  create_k8s_admin           = var.settings.clusters[var.cluster][var.color].vault.create_k8s_admin ? 1 : 0
  istio_expose               = var.settings.clusters[var.cluster][var.color].vault.istio_expose ? 1 : 0
}
