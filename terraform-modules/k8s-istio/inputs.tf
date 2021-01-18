
data "google_compute_instance" "bastion" {
  name = var.Settings.bastion_hostname
  zone = var.Settings.bastion_zone
}

data "external" "onetime_ssh_key" {
  program = ["sh", "${path.module}/../generate-temp-ssh-key.sh"]
}

data "google_client_openid_userinfo" "userinfo_of_account_who_running_terraform" {
}

data "google_service_account" "account_who_running_terraform" {
  account_id = element(split("@", data.google_client_openid_userinfo.userinfo_of_account_who_running_terraform.email), 0)
}

data "google_project" "current_project" {
}

variable "GkeClusterConnectionSettings" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  bastionExposeToggle = (
    lookup(var.Settings.clusters[var.Cluster][var.Color].istio, "expose_istio_ingres_on_bastion", false) ||
    lookup(var.Settings.clusters[var.Cluster][var.Color], "active", false)
  ) ? 1 : 0

  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    CLUSTER_SETTINGS        = jsonencode(var.Settings)
    CLUSTER                 = var.Cluster
    COLOR                   = var.Color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.Settings.bastion_dns
  })
}
