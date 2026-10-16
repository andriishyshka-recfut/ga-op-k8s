variable "Settings" {
  description = "Repository-wide environment settings."
  type        = any
}

variable "Cluster" {
  description = "Cluster key used to select Settings.clusters."
  type        = string
}

variable "RestoreBackupName" {
  description = "Full backup directory name, for example full-20261008T020000Z."
  type        = string

  validation {
    condition     = can(regex("^full-[0-9]{8}T[0-9]{6}Z$", var.RestoreBackupName))
    error_message = "RestoreBackupName must have the format full-YYYYMMDDTHHMMSSZ."
  }
}

variable "RestoreRunId" {
  description = "Explicit identifier for this restore; change it to request another run."
  type        = string

  validation {
    condition     = length(var.RestoreRunId) <= 24 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.RestoreRunId))
    error_message = "RestoreRunId must be a lowercase DNS label of 1 to 24 characters."
  }
}

variable "RestoreDatabase" {
  description = "Database to restore under its original name; empty restores all databases."
  type        = string
  default     = ""
}

locals {
  clickhouse            = var.Settings.clusters[var.Cluster].clickhouse
  cluster_name          = "clickhouse"
  namespace             = "clickhouse"
  clickhouse_host       = "${local.cluster_name}-clickhouse-headless"
  clickhouse_cluster    = "default"
  clickhouse_secret     = "${local.cluster_name}-default-user"
  clickhouse_tls_secret = "${local.cluster_name}-tls"
  clickhouse_image      = "clickhouse/clickhouse-server:${var.Settings.clusters[var.Cluster].versions.clickhouse.image_tag}"
  backup_disk_name      = "backups"
  restore_job_name      = "${substr(local.cluster_name, 0, 26)}-restore-${var.RestoreRunId}"
}
