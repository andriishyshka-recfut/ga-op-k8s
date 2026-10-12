variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  clusterName = "${var.Cluster}-${var.Color}"
  backupdate  = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.coldBackupDate
  zones       = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
  region      = "us-east4"
  services  = merge([
    for service_name, groups in var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services : merge([
      for group_name, group_cfg in groups : {
        for idx in range(group_cfg.count) :
        "${service_name}-${group_name}-${idx}" => merge(
          group_cfg,
          {
            service = service_name
            role    = group_name
            index   = idx
          }
        )
      }
    ]...)
  ]...)

  # mongo_count       = var.Cluster == "production" ? var.Settings.clusters[var.Cluster].mongo6.main.replicas : var.Settings.clusters[var.Cluster].mongo6.main.replicas
  # mongo_prefix      = var.Cluster == "production" ? var.Settings.clusters[var.Cluster].mongo6.main.pvcPrefix : var.Settings.clusters[var.Cluster].mongo6.main.pvcPrefix
  # mongo_auth_count  = var.Settings.clusters[var.Cluster].mongo6.auth.replicas
  # mongo_auth_prefix = var.Settings.clusters[var.Cluster].mongo6.auth.pvcPrefix

  # kafka_count  = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.kafka.count
  # kafka_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.kafka.kafka_prefix

  # #Uncomment for Prod DR:
  # # zookeeper_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.kafka.zookeeper_prefix

  # #Comment for Prod DR:
  # controller_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.kafka.controller_prefix

  # sonarqube_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.sonarqube.count
  # minio_count     = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.minio.count
  # minio_prefix    = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.minio.prefix
  # # mongoDiskSize = trim(var.Settings.clusters[var.Cluster].mongo.magescanner.volumeSize, "Gi")
  # # mongoAuthDiskSize = trim(var.Settings.clusters[var.Cluster].mongo.magescanner.volumeSize, "Gi")
  # postgres_count = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.postgres.count


  # tarantool_storage_count  = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_disks * 2
  # tsc                      = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_disks
  # tarantool_storage_prefix = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.storage_prefix
  # tarantool_router_count   = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.router_disks
  # tarantool_router_prefix  = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.tarantool.router_prefix

}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
