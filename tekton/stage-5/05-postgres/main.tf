locals {
  postgres_settings    = try(var.Settings.clusters[var.Cluster].postgres, {})
  postgres_ha_settings = try(var.Settings.clusters[var.Cluster]["postgresql-ha"], {})

  enable_postgres    = lookup(local.postgres_settings, "enabled", true)
  enable_postgres_ha = lookup(local.postgres_ha_settings, "enabled", false)
}

module "postgres" {
#  count                        = local.enable_postgres ? 1 : 0
  source                       = "../../../terraform-modules/k8s-vault-postgres"
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  VaultAddress                 = var.VaultAddress
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}

module "postgres_ha" {
#  count                        = local.enable_postgres_ha ? 1 : 0
  source                       = "../../../terraform-modules/k8s-vault-postgres-ha"
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  VaultAddress                 = var.VaultAddress
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
