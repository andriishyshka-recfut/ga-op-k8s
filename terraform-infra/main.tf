
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

# module "gke-setup2" {
#   source = "../terraform-modules/gke-setup"
#
#   settings = module.common-vars
#   cluster = "dev"
# }
