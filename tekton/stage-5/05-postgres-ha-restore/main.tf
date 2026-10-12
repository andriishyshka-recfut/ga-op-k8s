module "postgres_ha_restore" {
  count                  = trimspace(var.PostgresqlHaProfile) != "" && trimspace(var.RestoreDatabase) != "" ? 1 : 0
  source                 = "../../../terraform-modules/k8s-vault-postgres-ha-restore"
  Cluster                = var.Cluster
  Settings               = var.Settings
  PostgresqlHaProfile    = var.PostgresqlHaProfile
  RestoreDatabase        = var.RestoreDatabase
  RestoreBackupTimestamp = var.RestoreBackupTimestamp
  RestoreJobName         = var.RestoreJobName
}
