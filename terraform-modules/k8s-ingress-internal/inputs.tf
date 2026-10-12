variable "Settings" {}
variable "Cluster" {}
variable "k8s" {}
variable "resource_type" { default = "all" }

locals {
  internalIngressSettings = lookup(var.Settings.clusters[var.Cluster], "ingress-internal", {})
  internalStaticIps       = lookup(var.Settings, "internal_static_ips", {})
  ingresses               = { for name, data in local.internalIngressSettings : name => data if !lookup(data, "service", false) && contains(["all", "ingresses"], var.resource_type)}
  services                = { for name, data in local.internalIngressSettings : name => data if lookup(data, "service", false) && contains(["all", "services"], var.resource_type)}
}

