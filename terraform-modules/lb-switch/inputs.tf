
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

data "google_container_cluster" "red_cluster" {
  count    = local.isProduction
  name     = "production-red"
  location = "us-east4"
}

data "google_client_config" "default" {
}

data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}

locals {
  activeCluster   = var.Color
  inActiveCluster = var.Color == "blue" ? "green" : "blue"
  harbor          = var.Harbor ? 1 : 0
  isProduction    = var.Cluster == "production" ? 1 : 0
  inactiveClusterVaultPath = "secret/kubernetes-${var.Cluster}-${local.inActiveCluster}"

  inActiveGkeEndpoint = "https://${data.google_container_cluster.inactive_cluster.endpoint}"
  gkeClusterConnectionSettings = {
    HOST                   = "https://${data.google_container_cluster.active_cluster.endpoint}"
    API_KEY                = data.google_client_config.default.access_token
    CLUSTER_CA_CERTIFICATE = base64decode(data.google_container_cluster.active_cluster.master_auth.0.cluster_ca_certificate, )
  }
  gkeRedClusterConnectionSettings = local.isProduction == 1 ? {
    RED_HOST                   = "https://${data.google_container_cluster.red_cluster[0].endpoint}"
    RED_API_KEY                = data.google_client_config.default.access_token
    RED_CLUSTER_CA_CERTIFICATE = base64decode(data.google_container_cluster.red_cluster[0].master_auth.0.cluster_ca_certificate, )
  } : {}
  ansibleEnvs = merge(local.gkeClusterConnectionSettings, local.gkeRedClusterConnectionSettings, {
    CLUSTER_SETTINGS        = jsonencode(var.Settings)
    CLUSTER                 = var.Cluster
    COLOR                   = local.activeCluster
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.Settings.bastion_dns
  })
  load_balancer_ip  = var.Settings.clusters[var.Cluster].load_balancer_ip
  VaultAddress      = element(split("/", var.VaultAddress), length(split("/", var.VaultAddress)) - 1)
  ports             = var.Settings.clusters[var.Cluster][var.Color].istio.lb
  delete_lb_service = <<COMMAND
      kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     delete svc istio-ingressgateway-lb -n istio-ingress 
  COMMAND
}
