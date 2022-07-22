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
  gkeClusterEndpoint   = module.gke-setup-green.GkeClusterConnectionSettings.HOST
  gkeBearerToken       = module.gke-setup-green.GkeClusterConnectionSettings.API_KEY
  clusterCaCertificate = module.gke-setup-green.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
  # gkeClusterEndpoint   = module.gke-setup-green.HOST
  # gkeBearerToken       = module.gke-setup-green.API_KEY
  # clusterCaCertificate = module.gke-setup-green.CLUSTER_CA_CERTIFICATE
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
  cluster_ca_certificate = local.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
  host                   = local.GkeClusterConnectionSettings.HOST
  token                  = local.GkeClusterConnectionSettings.API_KEY
  load_config_file       = false
}
terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "tf-blue-green/blue-state-cluster"
  }
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}
EOF
}