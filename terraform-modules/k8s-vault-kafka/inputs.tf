variable "GkeClusterConnectionSettings" {}
variable "Cluster" {}
variable "Settings" {}


locals {
  kafkaNs = "kafka"
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
  })
  limit    = var.Cluster == "production" ? { "memory" : "9G", "cpu" : "5" } : { "memory" : "2G", "cpu" : "1" }
  request  = var.Cluster == "production" ? { "memory" : "3G", "cpu" : "1" } : { "memory" : "1G", "cpu" : "0.25" }
  pv_disk_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.kafka.count
  replicas = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.kafka.count
  zones = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
