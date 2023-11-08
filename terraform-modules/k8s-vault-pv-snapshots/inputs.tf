variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  clusterName = "${var.Cluster}-${var.Color}"
  backupdate  = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.coldBackupDate
  zones       = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
  region      = "us-east4"


  mongo_count       = var.Settings.clusters[var.Cluster].mongo.magescanner.replicas
  mongo_prefix      = var.Settings.clusters[var.Cluster].mongo.magescanner.pvcPrefix
  mongo_auth_count  = var.Settings.clusters[var.Cluster].mongo.auth.replicas
  mongo_auth_prefix = var.Settings.clusters[var.Cluster].mongo.auth.pvcPrefix

  kafka_count      = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.kafka.count
  kafka_prefix     = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.kafka.kafka_prefix
  zookeeper_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.kafka.zookeeper_prefix
  tarantool_count  = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.count
  sonarqube_count  = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.sonarqube.count
  sftp             = var.Settings.clusters[var.Cluster].sftp-server
  minio_count      = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.minio.count
  minio_prefix      = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.minio.prefix
  # mongoDiskSize = trim(var.Settings.clusters[var.Cluster].mongo.magescanner.volumeSize, "Gi")
  # mongoAuthDiskSize = trim(var.Settings.clusters[var.Cluster].mongo.magescanner.volumeSize, "Gi")

  tarantool_storage_count = var.Cluster == "production" ? 0 : var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_disks * 2
  tsc = var.Cluster == "production" ? 0 : var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_disks 
  tarantool_storage_prefix = var.Cluster == "production" ? 0 : var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_prefix 
  tarantool_router_count = var.Cluster == "production" ? 0 : var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.router_disks
  tarantool_router_prefix = var.Cluster == "production" ? 0 : var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.router_prefix 

}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
