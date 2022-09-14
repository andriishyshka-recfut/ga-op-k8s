terraform {

  extra_arguments "custom_vars" {
    commands = [
      "init",
      "apply",
      "plan",
      "import",
      "push",
      "refresh",
      "destroy"
    ]

    required_var_files = ["${get_parent_terragrunt_dir()}/../../../../${get_env("CONF_PATH")}"]
  }
}
dependencies {
  paths = ["../cluster"]
}

dependency "cluster" {
  config_path = "../cluster"
}

inputs = {
  GkeClusterConnectionSettings = dependency.cluster.outputs.GkeClusterConnectionSettings
}


generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "google" {
}

provider "google-beta" {
}

provider "vault" {
  address = "https://vault.p.regemini.io"
}

locals {
  gkeClusterEndpoint   = local.GkeClusterConnectionSettings.HOST
  gkeBearerToken       = local.GkeClusterConnectionSettings.API_KEY
  clusterCaCertificate = local.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
 # gkeClusterEndpoint   = data.vault_generic_secret.GkeClusterConnectionSettings.data["HOST"]
 # gkeBearerToken       = data.vault_generic_secret.GkeClusterConnectionSettings.data["API_KEY"]
 # clusterCaCertificate = data.vault_generic_secret.GkeClusterConnectionSettings.data["CLUSTER_CA_CERTIFICATE"]
}

provider "helm" {
  kubernetes {
    host                   = local.gkeClusterEndpoint
    token                  = local.gkeBearerToken
    cluster_ca_certificate = local.clusterCaCertificate
  }
}

provider "kubernetes" {
  host                   = local.gkeClusterEndpoint
  token                  = local.gkeBearerToken
  cluster_ca_certificate = local.clusterCaCertificate
}

provider "kubectl" {
  # alias = "kube"
  cluster_ca_certificate = local.clusterCaCertificate
  host                   = local.gkeClusterEndpoint
  token                  = local.gkeBearerToken
  load_config_file       = false
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-prod-green/state-main"
  }
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

EOF
}