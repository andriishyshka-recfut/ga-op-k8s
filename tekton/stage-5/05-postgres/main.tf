locals {
  enable_postgres      = lookup(try(var.Settings.clusters[var.Cluster].postgres, {}), "enabled", false)
  postgres_ha_profiles = try(var.Settings.clusters[var.Cluster]["postgresql-ha"], {})
  enabled_postgres_ha_profiles = {
    for name, cfg in local.postgres_ha_profiles : name => cfg
    if lookup(cfg, "enabled", false)
  }
}

module "postgres" {
  count                        = local.enable_postgres ? 1 : 0
  source                       = "../../../terraform-modules/k8s-vault-postgres"
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  VaultAddress                 = var.VaultAddress
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}

module "postgres_ha" {
  for_each            = local.enabled_postgres_ha_profiles
  source              = "../../../terraform-modules/k8s-vault-postgres-ha"
  Cluster             = var.Cluster
  Settings            = var.Settings
  PostgresqlHaProfile = each.key
}
