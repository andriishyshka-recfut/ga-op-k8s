
provider "vault" {
  address = "https://vault.p.digaweb.com"
}
variable "Settings" {}
locals {

  activeCluster            = lookup(var.Settings.clusters.production.blue, "active", false) == true ? "blue" : "green"
  inactiveCluster          = local.activeCluster == "blue" ? "green" : "blue"
  activeClusterVaultPath   = "secret/kubernetes-production-${local.activeCluster}"
  inactiveClusterVaultPath = "secret/kubernetes-production-${local.inactiveCluster}"
}


data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}


provider "kubernetes" {
  alias = "kubernetes-inactive"
  # load_config_file       = false
  host                   = data.vault_generic_secret.k8s_auth_inactive.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth_inactive.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token
}
provider "google" {
  # version = "v3.19.0"
}



terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-backups/state"
  }
}
