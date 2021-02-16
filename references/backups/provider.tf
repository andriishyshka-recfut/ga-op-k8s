
provider "vault" {
  address = "https://vault.infra.digaweb.com"
}

data "vault_generic_secret" "k8s_auth" {
  path = "secret/kubernetes-sandbox-green"
}

provider "helm" {
  # alias = "helm"
  kubernetes {
    # load_config_file       = false
    host                   = data.vault_generic_secret.k8s_auth.data.HOST
    cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
    token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
  }
}

provider "kubernetes" {
  # alias                  = "kubernetes"
  # load_config_file       = false
  host                   = data.vault_generic_secret.k8s_auth.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
}

provider "google" {
  # version = "v3.19.0"
}


variable "Settings" {}





locals {

  gkeClusterConnectionSettings = {
    HOST                   = data.vault_generic_secret.k8s_auth.data.HOST
    API_KEY                = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  }
}
