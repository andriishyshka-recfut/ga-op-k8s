
terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "terraform-infra/state"
  }
}



module "common-vars" {
  source = "../terraform-modules/common-vars"
}

module "gke-setup" {
  source = "../terraform-modules/gke-setup"

  settings = module.common-vars
  cluster  = "infra"
  # vault_ca_certificate = module.vault.vault_ca_certificate
  # vault_addr     = module.vault.vault_addr
  vault_unsealed = module.vault.vault_unsealed
}

provider "google" {
  alias   = "google"
  version = "v3.19.0"
}

provider "helm" {
  alias = "helm"
  kubernetes {
    load_config_file       = false
    host                   = module.gke-setup.gke_cluster_endpoint
    token                  = module.gke-setup.gke_bearer_token
    cluster_ca_certificate = module.gke-setup.cluster_ca_certificate
  }
}

provider "kubernetes" {
  alias                  = "kubernetes"
  load_config_file       = false
  host                   = module.gke-setup.gke_cluster_endpoint
  token                  = module.gke-setup.gke_bearer_token
  cluster_ca_certificate = module.gke-setup.cluster_ca_certificate

}



variable "oidc_discovery_url" { default = "SAMPLE" }
variable "oidc_client_id" { default = "SAMPLE" }
variable "oidc_client_secret" { default = "SAMPLE" }

module "vault" {
  source                         = "../terraform-modules/vault"
  gke_cluster_endpoint           = module.gke-setup.gke_cluster_endpoint
  gke_bearer_token               = module.gke-setup.gke_bearer_token
  cluster_ca_certificate         = module.gke-setup.cluster_ca_certificate
  settings                       = module.common-vars
  cluster                        = "infra"
  vault-version                  = "1.4.2"
  oidc_discovery_url             = var.oidc_discovery_url
  oidc_client_id                 = var.oidc_client_id
  oidc_client_secret             = var.oidc_client_secret
  bucket_name                    = google_storage_bucket.vault.name
  autounseal_kms_crypto_key_id   = google_kms_crypto_key.vault-init.id
  autounseal_kms_crypto_key_name = google_kms_crypto_key.vault-init.name
  autounseal_kms_key_ring_name   = google_kms_key_ring.vault.name
  // Expose vault with istio as option default = false
  expose_vault_with_istio = module.gke-setup.istio_provisioned
  providers = {
    google     = google.google
    kubernetes = kubernetes.kubernetes
    helm       = helm.helm

  }
}
