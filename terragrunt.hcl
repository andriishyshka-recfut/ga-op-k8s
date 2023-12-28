
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

    required_var_files = ["${get_parent_terragrunt_dir()}/${get_env("CONF_PATH")}"]
  }
}

retryable_errors = [
  "isn't valid for cluster, check the APIVersion and Kind fields are valid",
  "'dict object' has no .* attribute 'status'",
  "Provider produced inconsistent final plan"
]

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "VaultAddress" {}


provider "vault" {
  address = var.VaultAddress
}

locals {

  activeCluster          = var.Color
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

provider "kubectl" {
    # alias = "kube"
    cluster_ca_certificate = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
    host                   = data.vault_generic_secret.k8s_auth.data.HOST
    token                  = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    load_config_file       = false
  }

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "kubernetes" {
    secret_suffix    = "${element(split("/", get_terragrunt_dir()), length(split("/", get_terragrunt_dir())) - 1)}-state"
    namespace = "tekton-pipelines"
    config_path = "./kubeconfig"
  }
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

provider "random" {}

EOF
}
