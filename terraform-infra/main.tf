
terraform {
  backend "gcs" {
    bucket  = "terraform-state-222"
    prefix  = "terraform-infra/state"
  }
}



module "common-vars" {
  source = "../terraform-modules/common-vars"
}

module "gke-setup" {
  source = "../terraform-modules/gke-setup"

  settings = module.common-vars
  cluster = "infra"
}

 module "vault" {
   source = "../terraform-modules/vault"
   gke_cluster_endpoint = module.gke-setup.gke_cluster_endpoint
   gke_bearer_token = module.gke-setup.gke_bearer_token
   cluster_ca_certificate = module.gke-setup.cluster_ca_certificate
 }
