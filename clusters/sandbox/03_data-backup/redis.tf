# module "redis-backup" {
#   source         = "../../../terraform-modules/k8s-vault-redis-backup"
#   BackupSettings = var.Settings.clusters["sandbox"].redisBackupSettings
#   Cluster        = var.Cluster
#   Color          = local.inactiveCluster
#   providers = {
#     kubernetes = kubernetes.kubernetes-inactive
#   }
# }
module "redis-restore" {
  source         = "../../../terraform-modules/k8s-vault-redis-restore"
  BackupSettings = var.Settings.clusters["sandbox"].redisBackupSettings
  Cluster        = var.Cluster
  Color          = local.activeCluster
  # depends_on     = [module.redis-backup]
}
