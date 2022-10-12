variable "Settings" {}
variable "Cluster" {}

locals {
  ipWhiteListCheck = lookup(var.Settings.clusters[var.Cluster], "ip_white_list", {})
  ipWhiteList      = { for whitelist, data in local.ipWhiteListCheck : whitelist => data }
}