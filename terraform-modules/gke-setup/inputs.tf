
data "google_compute_network" "vpc" {
  name = var.settings.vpc_name
}


data "google_compute_instance" "bastion" {
  name = var.settings.bastion_hostname
  zone = var.settings.bastion_zone
}

data "google_project" "current" {}
data "google_client_openid_userinfo" "me" {
}
data "google_service_account" "me" {
  account_id = element(split("@", data.google_client_openid_userinfo.me.email), 0)
}
data "google_client_config" "default" {
}


# data "external" "eck_crd" {
#   # count   = lookup(var.settings[var.cluster].vault_integration, "connection", "remote") == "local" ? 0 : 1
#   program = ["python3", "${path.module}/../data-get-eck-crd.py"]
#   query = {
#     eck_version = lookup(var.settings[var.cluster], "eck_version", "1.1.2")
#   }
# }


// Cluster settings from module common-vars
variable "settings" {}
variable "cluster" {}
