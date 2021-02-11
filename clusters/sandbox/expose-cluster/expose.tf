# Update LB configuration and create ingresses


provider "google" {
}

provider "vault" {
  address = "https://vault.infra.digaweb.com"
}

variable "Settings" {}


data "vault_generic_secret" "k8s_auth" {
  path = local.activeClusterVaultPath
}

locals {
  # activeCluster = lookup(var.Settings.clusters.sandbox.blue, "active", false) == true ? "blue" : "green"
  activeCluster = "blue"
  # activeClusterVaultPath = "secret/kubernetes-sandbox-${local.activeCluster}"
  activeClusterVaultPath = "secret/kubernetes-sandbox"
  gkeClusterConnectionSettings = {
    HOST                   = data.vault_generic_secret.k8s_auth.data.HOST
    API_KEY                = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  }
}

provider "kubernetes" {
  host                   = data.vault_generic_secret.k8s_auth.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-lb-switch/state"
  }
  required_providers {
    kubernetes = {
      version = "2.0.1"
    }
  }

}

module "lb-switch" {
  source                       = "../../../terraform-modules/lb-switch"
  Settings                     = var.Settings
  Cluster                      = "sandbox"
  Color                        = local.activeCluster
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
