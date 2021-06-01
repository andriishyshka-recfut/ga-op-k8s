
variable "OidcSecretVaultPath" {
  default = "secret/oidc_google_prod"
}


locals {
  prometheusNs = "monitoring"
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
