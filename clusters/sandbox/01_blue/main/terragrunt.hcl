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
  # version = "v3.19.0"
}

provider "google-beta" {
  # version = "v3.19.0"
}

provider "vault" {
  address = "https://vault.t.regemini.io"
}

locals {
  gkeClusterEndpoint   = local.GkeClusterConnectionSettings.HOST
  gkeBearerToken       = local.GkeClusterConnectionSettings.API_KEY
  clusterCaCertificate = local.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
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
    bucket = "terraform-state-222"
    prefix = "tf-blue-green/blue-state-main"
  }
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

EOF
}