
data "google_compute_network" "vpc" {
  name = var.Settings.vpc_name
}


data "google_compute_instance" "bastion" {
  name = var.Settings.bastion_hostname
  zone = var.Settings.bastion_zone
}

data "google_project" "current" {}
data "google_client_openid_userinfo" "me" {
}
data "google_service_account" "me" {
  account_id = element(split("@", data.google_client_openid_userinfo.me.email), 0)
}
data "google_client_config" "default" {
}



// Cluster settings from module common-vars
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  isPreemptible = lookup(var.Settings.clusters[var.Cluster][var.Color], "preemptible", true)
  bluePods      = var.Settings.clusters[var.Cluster]["blue"].pods_subnet_range
  greenPods     = var.Settings.clusters[var.Cluster]["green"].pods_subnet_range
  blueNodes      = var.Settings.clusters[var.Cluster]["blue"].nodes_subnet_range
  greenNodes     = var.Settings.clusters[var.Cluster]["green"].nodes_subnet_range
}
