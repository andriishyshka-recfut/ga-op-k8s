
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  namespaces = var.Settings.clusters[var.Cluster].namespaces
}
