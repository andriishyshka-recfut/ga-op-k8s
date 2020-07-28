terraform {
  backend "gcs" {
    bucket = "terraform-state-222"
    prefix = "terraform-test/state"
  }
}

module "common-vars" {
  source = "../terraform-modules/common-vars"
}

module "gke-setup" {
  source = "../terraform-modules/gke-setup"

  settings                         = module.common-vars
  cluster                          = "test"
  vault_deployment_completion_lock = false
}
