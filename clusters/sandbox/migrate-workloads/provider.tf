
provider "vault" {
  address = "https://vault.infra.digaweb.com"
}

provider "google" {
  # version = "v3.19.0"
}

variable "Settings" {}


locals {
  activeCluster          = lookup(var.Settings.clusters.sandbox.blue, "active", false) == true ? "blue" : "green"
  inactiveCluster        = local.activeCluster == "blue" ? "green" : "blue"
  activeClusterVaultPath = "secret/kubernetes-sandbox-${local.activeCluster}"
  monitoringEs           = yamldecode(file("monitoring_elastic_settings.yaml"))
  dataEs                 = yamldecode(file("data_elastic_settings.yaml"))
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
  host                   = data.vault_generic_secret.k8s_auth.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-workloads/state-5"
  }
  required_providers {
    kubernetes = {
      version = "2.0.1"
    }
  }

}
output "ActiceCluuster" {
  value = local.activeCluster
}
