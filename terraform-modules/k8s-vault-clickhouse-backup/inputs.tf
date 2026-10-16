variable "Settings" {
  description = "Repository-wide environment settings."
  type        = any
}

variable "Cluster" {
  description = "Cluster key used to select Settings.clusters."
  type        = string
}

locals {
  clickhouse            = var.Settings.clusters[var.Cluster].clickhouse
  backup                = local.clickhouse.backup
  cluster_name          = "clickhouse"
  namespace             = "clickhouse"
  image_tag             = var.Settings.clusters[var.Cluster].versions.clickhouse.image_tag
  schedule              = local.backup.schedule
  retention_days        = local.backup.retention_days
  minimum_backups       = local.backup.minimum_backups
  endpoint              = "http://minio.minio:9000"
  bucket                = "minio-backup-${var.Settings.gcpProject}"
  path                  = "clickhouse"
  clickhouse_host       = "${local.cluster_name}-clickhouse-headless"
  clickhouse_cluster    = "default"
  clickhouse_secret     = "${local.cluster_name}-default-user"
  clickhouse_tls_secret = "${local.cluster_name}-tls"
  minio_secret          = "${local.cluster_name}-backup-minio"
  backup_disk_name      = "backups"
  clickhouse_image      = "clickhouse/clickhouse-server:${local.image_tag}"
  minio_client_image    = "harbor.regemini.io/op/postgres-minio-backup:pg17-aws"
  minio_backup_target   = "s3://${local.bucket}/${local.path}/${local.cluster_name}"
}
