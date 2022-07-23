
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "Harbor" {}
variable "VaultAddress" {}

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
  name     = "${var.Cluster}-${local.activeCluster}"
  location = "us-east4"
}

data "google_container_cluster" "inactive_cluster" {
  name     = "${var.Cluster}-${local.inActiveCluster}"
  location = "us-east4"
}

data "google_client_config" "default" {
}



locals {
  activeCluster   = var.Color
  inActiveCluster = var.Color == "blue" ? "green" : "blue"
  harbor          = var.Harbor ? 1 : 0

  inActiveGkeEndpoint = "https://${data.google_container_cluster.inactive_cluster.endpoint}"
  gkeClusterConnectionSettings = {
    HOST                   = "https://${data.google_container_cluster.active_cluster.endpoint}"
    API_KEY                = data.google_client_config.default.access_token
    CLUSTER_CA_CERTIFICATE = base64decode(data.google_container_cluster.active_cluster.master_auth.0.cluster_ca_certificate, )
  }
  ansibleEnvs = merge(local.gkeClusterConnectionSettings, {
    CLUSTER_SETTINGS        = jsonencode(var.Settings)
    CLUSTER                 = var.Cluster
    COLOR                   = local.activeCluster
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.Settings.bastion_dns
  })
  load_balancer_ip = var.Settings.clusters[var.Cluster].load_balancer_ip
}
