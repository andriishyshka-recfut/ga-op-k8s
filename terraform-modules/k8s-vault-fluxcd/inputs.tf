terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
    flux = {
      source  = "registry.terraform.io/fluxcd/flux"
      version = ">= 0.0.13"
    }
  }

}

variable "Cluster" {}
variable "Color" { }
