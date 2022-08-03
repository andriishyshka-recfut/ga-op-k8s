variable "Settings" {}
variable "Cluster" {}

locals {
  ingressSettings = var.Settings.clusters[var.Cluster].ingress
}
