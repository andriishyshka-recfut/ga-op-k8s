data "google_compute_instance" "bastion" {
  name = var.settings.bastion_hostname
  zone = var.settings.bastion_zone
}

data "google_compute_network" "vpc" {
  name = var.settings.vpc_name
}



variable "settings" {}

variable "cluster" { }
