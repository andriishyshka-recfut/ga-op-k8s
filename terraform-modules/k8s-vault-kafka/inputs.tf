variable "GkeClusterConnectionSettings" {}
variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "artifactoryRepoDomain" {}


locals {
  kafkaNs = "kafka"
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
  })
  limit         = var.Cluster == "production" ? { "memory" : "8G", "cpu" : "5" } : { "memory" : "2G", "cpu" : "1" }
  request       = var.Cluster == "production" ? { "memory" : "7G", "cpu" : "3" } : { "memory" : "1G", "cpu" : "250m" }
  pv_disk_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.kafka.data.count
  replicas      = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.kafka.data.count
  zones         = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
  rp_image_tag  = var.Settings.clusters[var.Cluster].versions.red-panda.image_tag

  operatorChartVersion = var.Settings.clusters[var.Cluster].versions.kafka.operator_chart_version
  kafkaVersion         = var.Settings.clusters[var.Cluster].versions.kafka.kafka_version
}

# terraform {
#   required_providers {
#     kubectl = {
#       source  = "registry.terraform.io/gavinbunney/kubectl"
#       version = ">= 1.10.0"
#     }
#   }
# }
