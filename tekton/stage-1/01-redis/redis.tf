module "redis" {
  source         = "../../../terraform-modules/k8s-redis"
  RedisSettings = var.Settings.clusters[var.Cluster].redisSettings
}
