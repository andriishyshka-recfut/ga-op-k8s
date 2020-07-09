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

// Cluster settings from module common-vars
variable "settings" {}
variable "cluster" {}

variable "vault_deployment_completion_lock" {}
