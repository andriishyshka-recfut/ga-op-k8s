
provider "vault" {
  address = "https://vault.p.digaweb.com"
}

locals {

  activeCluster          = lookup(var.Settings.clusters.production.blue, "active", false) == true ? "blue" : "green"
  activeClusterVaultPath = "secret/kubernetes-production-${local.activeCluster}"

  gkeClusterConnectionSettings = {
    HOST                   = data.vault_generic_secret.k8s_auth.data.HOST
    API_KEY                = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  }
}

data "vault_generic_secret" "k8s_auth" {
  path = local.activeClusterVaultPath
}

provider "kubernetes" {
  host                   = data.vault_generic_secret.k8s_auth.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
}

provider "google" {
  # version = "v3.19.0"
}


variable "Settings" {}

terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-lb-switch/state"
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
  Cluster                      = "production"
  Color                        = local.activeCluster
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
