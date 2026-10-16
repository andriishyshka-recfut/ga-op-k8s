module "clickhouse_restore" {
  source            = "../../../terraform-modules/k8s-vault-clickhouse-restore"
  Settings          = var.Settings
  Cluster           = var.Cluster
  RestoreBackupName = var.RestoreBackupName
  RestoreRunId      = var.RestoreRunId
  RestoreDatabase   = var.RestoreDatabase
}
