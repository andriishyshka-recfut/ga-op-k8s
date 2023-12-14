
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  namespace = "vortex"

  tarantool_storage_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_disks * 2
  tsc = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_disks 
  tarantool_storage_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_prefix 
  tarantool_router_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.router_disks
  tarantool_router_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.router_prefix 
  tarantool_etcd_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.etcd_disks
  tarantool_etcd_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.etcd_prefix 

  storage_request_cpu = var.Cluster == "production" ?  "500m" : "300m"
  storage_request_mem = var.Cluster == "production" ?  "6.7G" : "2.2G"
  storage_limit_cpu = var.Cluster == "production" ?  "2" : "500m"
  storage_limit_mem = var.Cluster == "production" ?  "6.7G" : "2.2G"

  storage_memtx_memory =  var.Cluster == "production" ?  "6.5G" : "2G"


  zones = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
}

