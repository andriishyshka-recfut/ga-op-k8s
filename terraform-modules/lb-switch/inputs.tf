
variable "Settings" {}
variable "Cluster" {}



locals {

  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    CLUSTER_SETTINGS        = jsonencode(var.Settings)
    CLUSTER                 = var.Cluster
    COLOR                   = var.Color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.Settings.bastion_dns
  })
}

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


data "google_container_cluster" "active_cluster" {
  name     = "sandbox-${local.activeCluster}"
  location = "us-east4"
}

data "google_client_config" "default" {
}

locals {
  activeCluster = lookup(var.Settings.clusters.sandbox.blue, "active", false) == true ? "blue" : "green"
  # activeCluster = "blue"
  gkeClusterConnectionSettings = {
    HOST                   = "https://${data.google_container_cluster.active_cluster.endpoint}"
    API_KEY                = data.google_client_config.default.access_token
    CLUSTER_CA_CERTIFICATE = base64decode(data.google_container_cluster.active_cluster.master_auth.0.cluster_ca_certificate, )
  }
}
