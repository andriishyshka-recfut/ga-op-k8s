
# provider "google" {
#   # version = "v3.19.0"
# }
#
#
# provider "vault" {
#   address = "https://vault.infra.digaweb.com"
# }
#
# variable "Settings" {}
#
#
# locals {
#   activeCluster            = lookup(var.Settings.clusters.sandbox.blue, "active", false) == true ? "blue" : "green"
#   inactiveCluster          = local.activeCluster == "blue" ? "green" : "blue"
#   activeClusterVaultPath   = "secret/kubernetes-sandbox-${local.activeCluster}"
#   inactiveClusterVaultPath = "secret/kubernetes-sandbox"
# }
# data "vault_generic_secret" "k8s_auth" {
#   path = local.activeClusterVaultPath
# }
#
# data "vault_generic_secret" "k8s_auth_inactive" {
#   path = local.inactiveClusterVaultPath
# }
#
#
# provider "kubernetes" {
#   # alias                  = "kubernetes"
#   host                   = data.vault_generic_secret.k8s_auth.data.HOST
#   cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
#   token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
# }
# provider "kubernetes" {
#   alias = "kubernetes-inactive"
#   # load_config_file       = false
#   host                   = data.vault_generic_secret.k8s_auth_inactive.data.HOST
#   cluster_ca_certificate = data.vault_generic_secret.k8s_auth_inactive.data.CLUSTER_CA_CERTIFICATE
#   token                  = data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token
# }

terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-backup/state"
  }
  required_providers {
    kubernetes = {
      version = "2.0.1"
    }
  }

}
