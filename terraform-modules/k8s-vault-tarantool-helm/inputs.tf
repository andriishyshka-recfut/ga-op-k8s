
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  namespace = "vortex"
  storage_count = var.Cluster == "production" ? 6 : 4
}

