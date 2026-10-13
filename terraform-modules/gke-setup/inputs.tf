
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
  isPreemptible       = lookup(var.Settings.clusters[var.Cluster], "preemptible", true)
  defaultMachineType  = lookup(var.Settings.clusters[var.Cluster], "defaultMachineType", "e2-standard-4")
  defaultNPdiskSizeGB = lookup(var.Settings.clusters[var.Cluster], "defaultNPdiskSizeGB", 60)
  additionalNodepools = var.Settings.clusters[var.Cluster].additionalNodepools
  # bluePods            = var.Settings.clusters[var.Cluster]["blue"].pods_subnet_range
  # greenPods           = var.Settings.clusters[var.Cluster]["green"].pods_subnet_range
  # redPods             = var.Settings.clusters[var.Cluster]["red"].pods_subnet_range
  gkeKmsVolumeKey = var.Settings.clusters[var.Cluster].persistent_resources.gke_kms_volume_key
  gkeRegion       = var.Settings.clusters[var.Cluster].region
  subnetIps       = [for color in var.ClusterColors : var.Settings.clusters[var.Cluster][color].subnets.pods_secondary_range]
  k8s_additional_subnets = { for subnet_name, subnet in lookup(var.Settings, "additional_subnets", {}) :
    subnet_name => [
      for range_name, range in lookup(subnet, "secondary_ip_ranges", {}) :
      range_name
      if try(range.color, null) == var.Color
    ]
    if anytrue([
      for range in values(lookup(subnet, "secondary_ip_ranges", {})) :
      try(range.color, null) == var.Color
    ])
  }
}



