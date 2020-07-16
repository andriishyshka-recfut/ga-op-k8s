data "google_compute_instance" "bastion" {
  name = var.settings.bastion_hostname
  zone = var.settings.bastion_zone
}

data "google_compute_network" "vpc" {
  name = var.settings.vpc_name
}

// Upload temp key to be able run ansible
data "external" "data" {
  program = ["sh", "../data.sh"]
}

data "google_client_openid_userinfo" "me" {
}
data "google_service_account" "me" {
  account_id = element(split("@", data.google_client_openid_userinfo.me.email), 0)
}
data "google_client_config" "default" {
}

data "external" "root_ca" {
  # count   = lookup(var.settings.cluster_settings[var.cluster].vault_integration, "connection", "remote") == "local" ? 0 : 1
  program = ["python3", "${path.module}/../data-vault-ca.py"]
  query = {
    vault_addr = lookup(var.settings.cluster_settings[var.cluster].vault_integration, "connection", "remote") == "local" ? "http://vault.vault.svc" : var.settings.cluster_settings[var.cluster].vault_integration.vault_addr
  }
  depends_on = [
    null_resource.ansible_vault_k8s_auth
  ]
}

data "external" "eck_crd" {
  # count   = lookup(var.settings.cluster_settings[var.cluster].vault_integration, "connection", "remote") == "local" ? 0 : 1
  program = ["python3", "${path.module}/../data-get-eck-crd.py"]
  query = {
    eck_version = lookup(var.settings.cluster_settings[var.cluster], "eck_version", "1.1.2")
  }
}


// Cluster settings from module common-vars
variable "settings" {}
variable "cluster" {}

variable "vault_deployment_completion_lock" {}
