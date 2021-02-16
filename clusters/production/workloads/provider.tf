
provider "vault" {
  address = "https://vault.p.digaweb.com"
}

locals {

  activeCluster          = lookup(var.Settings.clusters.production.blue, "active", false) == true ? "blue" : "green"
  inactiveCluster        = local.activeCluster == "blue" ? "green" : "blue"
  activeClusterVaultPath = "secret/kubernetes-production-${local.activeCluster}"
}

data "vault_generic_secret" "k8s_auth" {
  path = local.activeClusterVaultPath
}

provider "helm" {
  # alias = "helm"
  kubernetes {

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

provider "google" {
  # version = "v3.19.0"
}


variable "Settings" {}

terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-workloads/state-2"
  }
}
