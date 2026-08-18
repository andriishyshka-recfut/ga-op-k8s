module "redis" {
  source         = "../../../terraform-modules/k8s-redis"
  RedisSettings = var.Settings.clusters[var.Cluster].redisSettings
  Settings                     = var.Settings
  Cluster                      = var.Cluster
  Color                        = var.Color
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
