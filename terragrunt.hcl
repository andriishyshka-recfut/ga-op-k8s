
terraform {

extra_arguments "custom_vars" {
    commands = [
      "init",
      "apply",
      "plan",
      "import",
      "push",
      "refresh"
    ]

    required_var_files = ["${get_parent_terragrunt_dir()}/config.tfvars.json"]
  }
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
variable "Settings" {}
variable "Cluster" {}
variable "VaultAddress" {}


provider "vault" {
  address = var.VaultAddress
}

locals {

  activeCluster          = lookup(var.Settings.clusters[var.Cluster].blue, "active", false) == true ? "blue" : "green"
  inactiveCluster        = local.activeCluster == "blue" ? "green" : "blue"
  activeClusterVaultPath = "secret/kubernetes-$${var.Cluster}-$${local.activeCluster}"
  inactiveClusterVaultPath = "secret/kubernetes-$${var.Cluster}-$${local.inactiveCluster}"
  gkeClusterConnectionSettings = {
    HOST                   = data.vault_generic_secret.k8s_auth.data.HOST
    API_KEY                = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  }
}

data "vault_generic_secret" "k8s_auth" {
  path = local.activeClusterVaultPath
}

data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
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

provider "kubernetes" {
  alias = "kubernetes-inactive"
  host                   = data.vault_generic_secret.k8s_auth_inactive.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.k8s_auth_inactive.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token
}
EOF
}
