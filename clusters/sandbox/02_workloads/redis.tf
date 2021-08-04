module "redis" {
  source         = "../../../terraform-modules/k8s-redis"
  Redis_settings = var.Settings.clusters["sandbox"].redisSettings
}
