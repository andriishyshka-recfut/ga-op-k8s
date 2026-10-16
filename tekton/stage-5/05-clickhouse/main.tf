locals {
  clickhouse_enabled        = try(var.Settings.clusters[var.Cluster].clickhouse.enabled, false)
  clickhouse_backup_enabled = local.clickhouse_enabled && try(var.Settings.clusters[var.Cluster].clickhouse.backup.enabled, false)
}

module "clickhouse" {
  count        = local.clickhouse_enabled ? 1 : 0
  source       = "../../../terraform-modules/k8s-vault-clickhouse"
  Settings     = var.Settings
  Cluster      = var.Cluster
  Color        = var.Color
  VaultAddress = var.VaultAddress
}

module "clickhouse_backup" {
  count    = local.clickhouse_backup_enabled ? 1 : 0
  source   = "../../../terraform-modules/k8s-vault-clickhouse-backup"
  Settings = var.Settings
  Cluster  = var.Cluster

  depends_on = [module.clickhouse]
}
