data "google_compute_instance" "bastion" {
  name = module.common-vars.bastion_hostname
  zone = module.common-vars.bastion_zone
}

data "google_compute_network" "vpc" {
  name = module.common-vars.vpc_name
}


variable "region" {
  default = "us-east4"
}

module "common-vars" {
  source = "../terraform-modules/common-vars"
}

variable "cluster" {
  default = "infra"
}
