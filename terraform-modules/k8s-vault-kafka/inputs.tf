variable "GkeClusterConnectionSettings" {}
variable "Cluster" {}
variable "Settings" {}


locals {
  kafkaNs = "kafka"
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
  })
   diskSize = var.Cluster == "production" ? "700Gi" : "10Gi"
   limit = var.Cluster == "production" ? {"memory": "4G", "cpu": "3"} : {"memory": "2G", "cpu": "1"}
   request = var.Cluster == "production" ? {"memory": "3G", "cpu": "1"} : {"memory": "1G", "cpu": "0.25"}
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
