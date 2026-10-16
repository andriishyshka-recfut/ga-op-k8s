variable "Settings" {
  description = "Repository-wide environment settings."
  type        = any
}

variable "Cluster" {
  description = "Cluster key used to select Settings.clusters."
  type        = string
}

variable "Color" {
  description = "Cluster color used by the existing Vault Kubernetes auth mount."
  type        = string
}

variable "VaultAddress" {
  description = "Address of the environment Vault configured by the root module."
  type        = string
}

locals {
  clickhouse          = var.Settings.clusters[var.Cluster].clickhouse
  clickhouse_versions = var.Settings.clusters[var.Cluster].versions.clickhouse

  cluster_name       = "clickhouse"
  namespace          = "clickhouse"
  operator_namespace = "clickhouse-operator-system"

  chart_version = local.clickhouse_versions.chart_version
  image_tag     = local.clickhouse_versions.image_tag

  shards          = local.clickhouse.shards
  replicas        = local.clickhouse.replicas
  keeper_replicas = local.clickhouse.keeper_replicas

  clickhouse_storage_size = local.clickhouse.clickhouse_storage_size
  keeper_storage_size     = local.clickhouse.keeper_storage_size
  clickhouse_resources    = local.clickhouse.clickhouse_resources
  keeper_resources        = local.clickhouse.keeper_resources
  workloads_type          = local.clickhouse.workloadsType

  persistent_clickhouse = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.clickhouse
  disk_zones            = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.zones
  pv_selector_label     = "${local.cluster_name}-data"
  clickhouse_disks = merge([
    for shard in range(local.shards) : {
      for replica in range(local.replicas) : "${shard}-${replica}" => {
        shard      = shard
        replica    = replica
        name       = "${local.persistent_clickhouse["shard-${shard}"].prefix}-${replica}"
        zone       = try(local.persistent_clickhouse["shard-${shard}"].zones[replica], element(local.disk_zones, replica % 3))
        claim_name = "clickhouse-storage-volume-${local.cluster_name}-clickhouse-${shard}-${replica}-0"
      }
    }
  ]...)

  backup                  = local.clickhouse.backup
  backup_enabled          = local.backup.enabled
  backup_disk_name        = "backups"
  backup_secret_name      = "${local.cluster_name}-backup-minio"
  backup_minio_vault_path = "secret/minio/users"
  backup_minio_user       = "backup"
  backup_endpoint         = "http://minio.minio:9000/minio-backup-${var.Settings.gcpProject}/clickhouse/${local.cluster_name}/"

  vault_mount        = "secret"
  vault_auth_path    = "mw/clickhouse/auth"
  vault_cluster_path = "mw/clickhouse/cluster"

  keeper_name            = "${local.cluster_name}-keeper"
  password_secret_name   = "${local.cluster_name}-default-user"
  cluster_secret_name    = "${local.cluster_name}-cluster-credentials"
  tls_secret_name        = "${local.cluster_name}-tls"
  keeper_tls_secret_name = "${local.keeper_name}-tls"

  persistent_keeper     = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services["clickhouse-keeper"].data
  keeper_selector_label = "${local.keeper_name}-data"
  keeper_disks = {
    for replica in range(local.keeper_replicas) : tostring(replica) => {
      name       = "${local.persistent_keeper.prefix}-${replica}"
      zone       = try(local.persistent_keeper.zones[replica], element(local.disk_zones, replica % 3))
      claim_name = "clickhouse-storage-volume-${local.keeper_name}-keeper-${replica}-0"
    }
  }

  tls = {
    pki_mount = "pki-clickhouse"
    pki_role  = "clickhouse"
  }

  pod_template = {
    nodeSelector = {
      workloadsType = local.workloads_type
    }
    tolerations = [{
      key      = "workloadsType"
      operator = "Equal"
      value    = local.workloads_type
      effect   = "NoSchedule"
    }]
    nodeHostnameKey = "kubernetes.io/hostname"
    topologyZoneKey = "topology.kubernetes.io/zone"
  }
}
