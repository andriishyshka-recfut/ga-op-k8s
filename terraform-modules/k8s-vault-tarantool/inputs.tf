
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  pv_disk_count = var.Cluster == "production" ? 0 : 1
}