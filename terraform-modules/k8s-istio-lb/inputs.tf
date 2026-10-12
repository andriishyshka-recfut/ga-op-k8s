variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "RepositoryDomain" {}

locals {
  istio_ingresses = { for istio, istio_data in var.Settings.clusters[var.Cluster][var.Color].istio : istio => istio_data if istio != "bastion" }
  # ports           = var.Settings.clusters[var.Cluster][var.Color].istio.lb
}
