
provider "google" {
}

variable "Settings" {}
variable "Cluster" {}
variable "VaultAddress" {}

provider "vault" {
  address = var.VaultAddress
}

data "vault_generic_secret" "k8s_auth" {
  path = local.activeClusterVaultPath
}
locals {
  activeCluster          = "green" # Change color!!!!
  activeClusterVaultPath = "secret/kubernetes-${var.Cluster}-${local.activeCluster}"
}
provider "helm" {
  kubernetes = {
    host                   = data.vault_generic_secret.k8s_auth.data.HOST
    cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
    token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
  }
}
provider "kubernetes" {
  host                   = data.vault_generic_secret.k8s_auth.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-lb-switch/state-2026-09-12" # Change state!!!!
  }
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "3.3.0"
    }
  }
}

module "lb-switch" {
  source       = "../../../terraform-modules/lb-switch"
  Settings     = var.Settings
  Cluster      = var.Cluster
  VaultAddress = var.VaultAddress
  Color        = local.activeCluster
  Harbor       = false
}
