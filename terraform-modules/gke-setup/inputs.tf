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

variable "settings" {}

variable "cluster" {}

# terraform {
#   experiments = [variable_validation]
# }
#
# variable "vault_addr" {}
#   # validation {
#   #   condition     = length(var.vault_addr) > 1
#   #   error_message = "Hmm, vault_addr doesn't looks like url ."
#   #
#   # }
# }
#
# variable "vault_ca_certificate" {}
variable "vault_unsealed" {}
