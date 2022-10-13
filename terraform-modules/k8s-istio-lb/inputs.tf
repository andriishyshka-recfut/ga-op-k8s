variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  ports = var.Settings.clusters[var.Cluster][var.Color].istio.lb
}
