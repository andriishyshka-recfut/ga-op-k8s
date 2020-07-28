
data "external" "root_ca" {
  # count   = lookup(var.settings[var.cluster].vault_integration, "connection", "remote") == "local" ? 0 : 1
  program = ["python3", "${path.module}/../data-vault-ca.py"]
  query = {
    vault_addr = lookup(var.settings[var.cluster].vault_integration, "connection", "remote") == "local" ? "http://vault.vault.svc" : var.settings[var.cluster].vault_integration.vault_addr
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
  program = ["sh", "../data.sh"]
}

// k8s connection settings
variable "gke_cluster_endpoint" {}
variable "gke_bearer_token" {}
variable "cluster_ca_certificate" {}

// Cluster variables and settings from common-vars module
variable "settings" {}
variable "cluster" {}
// OIDC setup settings. Should be passed as env variables during execution
variable "oidc_discovery_url" { default = "SAMPLE" }
variable "oidc_client_id" { default = "SAMPLE" }
variable "oidc_client_secret" { default = "SAMPLE" }

variable "vault_resources" {}

variable "node_pool" {}
