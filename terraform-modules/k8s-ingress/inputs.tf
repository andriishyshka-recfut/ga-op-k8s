variable "Settings" {}
variable "Cluster" {}

locals {
  ingressSettings = var.Settings.clusters[var.Cluster].ingress
  # harbor          = lookup(var.Settings.clusters, "sandbox", false) ? 1 : 0
}
