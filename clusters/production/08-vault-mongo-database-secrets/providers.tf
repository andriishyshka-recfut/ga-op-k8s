provider "vault" {
  address = var.VaultAddress
}

provider "kubernetes" {
  host                   = data.vault_generic_secret.kubernetes_auth.data.HOST
  cluster_ca_certificate = data.vault_generic_secret.kubernetes_auth.data.CLUSTER_CA_CERTIFICATE
  token                  = data.vault_generic_secret.kubernetes_auth.data.k8s_sa_token
}

terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-vault-mongo-database-secrets/state"
  }

  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}
