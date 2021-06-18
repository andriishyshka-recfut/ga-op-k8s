
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  trac_setup = lookup(var.Settings.clusters[var.Cluster][var.Color], "trac_enable", "no") == "yes" ? 1 : 0
}
