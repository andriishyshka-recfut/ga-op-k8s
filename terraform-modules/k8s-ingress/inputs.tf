variable "Settings" {}
variable "Cluster" {}

locals {
  ingressSettings = var.Settings.clusters[var.Cluster].ingress
  certManager     = { for ingress, data in local.ingressSettings : ingress => data if lookup(var.Settings.clusters[var.Cluster].ingress[project], "cert-manager", false) }
}
