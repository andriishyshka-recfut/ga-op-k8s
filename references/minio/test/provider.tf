

variable "Settings" {}
variable "Cluster" {}
variable "VaultAddress" {}


provider "vault" {
  address = var.VaultAddress
}

locals {

  activeCluster          =  "green"

  activeClusterVaultPath = "secret/kubernetes-${var.Cluster}-${local.activeCluster}"
  gkeClusterConnectionSettings = {
    HOST                   = data.vault_generic_secret.k8s_auth.data.HOST
    API_KEY                = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  }
}

data "vault_generic_secret" "k8s_auth" {
  path = local.activeClusterVaultPath
}


provider "helm" {
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
}
