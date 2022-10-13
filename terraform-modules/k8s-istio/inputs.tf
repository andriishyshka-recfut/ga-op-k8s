
variable "GkeClusterConnectionSettings" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}





locals {

  ports = var.Settings.clusters[var.Cluster][var.Color].istio.bastion
  # ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
  #   CLUSTER_SETTINGS        = jsonencode(var.Settings)
  #   CLUSTER                 = var.Cluster
  #   COLOR                   = var.Color
  #   ANSIBLE_STDOUT_CALLBACK = "debug"
  #   BASTION_DNS             = var.Settings.bastion_dns
  # })
}
