variable "Settings" {}
variable "Cluster" {}
variable "k8s" {}

locals {
  internalIngressSettings = lookup(var.Settings.clusters[var.Cluster], "ingress-internal", {})
  internalStaticIps       = lookup(var.Settings, "internal_static_ips", {})
  ingresses               = { for name, data in local.internalIngressSettings : name => data if !lookup(data, "service", false) }
  services                = { for name, data in local.internalIngressSettings : name => data if lookup(data, "service", false) }
}

