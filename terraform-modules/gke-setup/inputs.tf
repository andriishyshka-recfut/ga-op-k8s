
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
variable "ClusterColors" {}

locals {
  isPreemptible       = lookup(var.Settings.clusters[var.Cluster][var.Color], "preemptible", true)
  defaultMachineType  = lookup(var.Settings.clusters[var.Cluster][var.Color], "defaultMachineType", "e2-standard-4")
  additionalNodepools = var.Settings.clusters[var.Cluster][var.Color].additionalNodepools
  # bluePods            = var.Settings.clusters[var.Cluster]["blue"].pods_subnet_range
  # greenPods           = var.Settings.clusters[var.Cluster]["green"].pods_subnet_range
  # redPods             = var.Settings.clusters[var.Cluster]["red"].pods_subnet_range
  gkeKmsVolumeKey = var.Settings.clusters[var.Cluster].persistent_resources.gke_kms_volume_key
  gkeRegion       = var.Settings.clusters[var.Cluster].region
  subnetIps       = [for color in var.ClusterColors : var.Settings.clusters[var.Cluster][color].pods_subnet_range]
}



