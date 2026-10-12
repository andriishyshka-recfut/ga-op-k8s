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

    required_var_files = ["${get_parent_terragrunt_dir()}/../../../${get_env("CONF_PATH")}"]
  }
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
  gkeClusterEndpoint   = module.gke-setup-red.GkeClusterConnectionSettings.HOST
  gkeBearerToken       = module.gke-setup-red.GkeClusterConnectionSettings.API_KEY
  clusterCaCertificate = module.gke-setup-red.GkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE

}

provider "helm" {
  kubernetes = {
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
    bucket = "terraform-state-production111"
    prefix = "terraform-prod-red/state"
  }
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}
EOF
}