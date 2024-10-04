variable "Cluster" {}
variable "Color" {}
variable "Settings" {}

locals {
  namespace = "kyverno"
  version   = var.Settings.clusters[var.Cluster].versions.kyverno.chart_version
}
