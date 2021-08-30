variable "GkeClusterConnectionSettings" {}
variable "Cluster" {}
variable "Settings" {}


locals {
  kafkaNs = "kafka"
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
  })
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
