variable "Settings" {}
variable "Cluster" {}

locals {
  ingressSettings = var.Settings.clusters[var.Cluster].ingress
  certManager     = { for ingress, data in toset(local.ingressSettings) : ingress => data if lookup(data, "cert-manager", false) }
}



