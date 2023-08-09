variable "Settings" {}
variable "Cluster" {}

locals {
  ipWhiteListCheck = lookup(var.Settings.clusters[var.Cluster], "ip_white_list", {})
  # ipWhiteList      = { for whitelist, data in local.ipWhiteListCheck : whitelist => data }
  ipWhiteListDraft = { for client, data in local.ipWhiteListCheck : client => { for ingress, service in data : ingress => distinct(flatten([for service_name, iplist in service : concat(iplist)])) } }
  ipWhiteList      = merge(flatten([for client, data in local.ipWhiteListDraft : [for ingress, iplist in data : { "${client}-${ingress}" = { "client" = client, "ingress" = ingress, "iplist" = iplist } }]])...)
}
