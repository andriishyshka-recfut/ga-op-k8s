
data "external" "root_ca" {
  program = ["python3", "${path.module}/../data-vault-ca.py"]
  query = {
    vault_addr = lookup(var.settings.clusters[var.cluster].vault_integration, "connection", "remote") == "local" ? "http://vault.vault.svc" : var.settings.clusters[var.cluster].vault_integration.vault_addr
  }
  depends_on = [
    null_resource.ansible_vault_k8s_auth
  ]
}

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
// k8s connection settings
variable "gke_cluster_endpoint" {}
variable "gke_bearer_token" {}
variable "cluster_ca_certificate" {}

// Cluster variables and settings from common-vars module
variable "settings" {}
variable "cluster" {}
variable "color" {}
// OIDC setup settings. Should be passed as env variables during execution
variable "oidc_discovery_url" { default = "SAMPLE" }
variable "oidc_client_id" { default = "SAMPLE" }
variable "oidc_client_secret" { default = "SAMPLE" }

# variable "vault_resources" {}

variable "node_pool" {}

locals {
  vault_bucket_name        = var.settings.clusters[var.cluster].persistent_resources.vault_bucket_name
  vault_key_name           = var.settings.clusters[var.cluster].persistent_resources.vault_key_name
  es_backup_bucket         = var.settings.clusters[var.cluster].persistent_resources.es_backup_bucket
  vault_service_account_id = var.settings.clusters[var.cluster].persistent_resources.vault_service_account_id
  project                  = data.google_service_account.me.project
}
