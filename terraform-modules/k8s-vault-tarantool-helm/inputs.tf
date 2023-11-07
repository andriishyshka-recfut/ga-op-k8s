
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  namespace = "vortex"
  storage_count = var.Cluster == "production" ? 6 : 6

  tarantool_storage_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_disks * 2
  tsc = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_disks 
  tarantool_storage_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_prefix 
  tarantool_router_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.router_disks
  tarantool_router_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.router_prefix 



  zones = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
}

