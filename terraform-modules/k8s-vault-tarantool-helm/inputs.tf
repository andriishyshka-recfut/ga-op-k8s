
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  namespace = "tarantool"

  tarantool_storage_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.tarantool.storage.count * 2
  tsc = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.tarantool.storage.count 
  tarantool_storage_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.tarantool.storage.prefix 
  tarantool_router_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.tarantool.router.count
  tarantool_router_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.tarantool.router.prefix 
  tarantool_etcd_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.tarantool.etcd.count
  tarantool_etcd_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.tarantool.etcd.prefix 

  storage_request_cpu = var.Cluster == "production" ?  "500m" : "300m"
  storage_request_mem = "2G" 
  storage_limit_cpu = var.Cluster == "production" ?  "2" : "500m"
  storage_limit_mem = var.Cluster == "production" ?  "4G" : "2.2G"

  storage_memtx_memory = "2G"

  operatorChartVersion = var.Settings.clusters[var.Cluster].versions.tarantool.operator_chart_version
  cartridgeChartVersion = var.Settings.clusters[var.Cluster].versions.tarantool.cartridge_chart_version
  cartridgeTag = var.Settings.clusters[var.Cluster].versions.tarantool.cartridge_tag

  # etcd_replica_count = var.Cluster == "production" ?  "7" : "1"
  
  zones = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
}

