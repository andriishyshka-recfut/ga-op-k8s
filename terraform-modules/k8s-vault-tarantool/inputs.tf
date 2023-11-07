
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  pv_disk_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.count
  pv_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.prefix
  zones         = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
}
