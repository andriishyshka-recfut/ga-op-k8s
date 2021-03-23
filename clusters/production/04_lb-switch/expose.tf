
provider "google" {
}

variable "Settings" {}
variable "Cluster" {}
variable "VaultAddress" {}

data "google_container_cluster" "active_cluster" {
  name     = "${var.Cluster}-${local.activeCluster}"
  location = "us-east4"
}

data "google_client_config" "default" {
}

locals {
  activeCluster          = lookup(var.Settings.clusters.production.blue, "active", false) == true ? "blue" : "green"
  gkeClusterConnectionSettings = {
    HOST                   = "https://${data.google_container_cluster.active_cluster.endpoint}"
    API_KEY                = data.google_client_config.default.access_token
    CLUSTER_CA_CERTIFICATE = base64decode(data.google_container_cluster.active_cluster.master_auth.0.cluster_ca_certificate, )
  }
}

provider "kubernetes" {
  host                   = local.gkeClusterConnectionSettings.HOST
  cluster_ca_certificate = local.gkeClusterConnectionSettings.CLUSTER_CA_CERTIFICATE
  token                  = local.gkeClusterConnectionSettings.API_KEY
}


terraform {
  backend "gcs" {
    bucket = "terraform-state-production111"
    prefix = "terraform-production-lb-switch/state"
  }
  required_providers {
    kubernetes = {
      version = "2.0.1"
    }
  }
}

module "lb-switch" {
  source                       = "../../../terraform-modules/lb-switch"
  Settings                     = var.Settings
  Cluster                      = "production"
  Color                        = local.activeCluster
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
