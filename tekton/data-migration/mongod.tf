# module "mongod-backup" {
#   for_each = var.Settings.clusters[var.Cluster].mongo
#   source = "../../terraform-modules/k8s-vault-mongo-backup"
#   BackupSettings = each.value.mongoMigrateSettings
#   BackupBucket = each.value.backupBucket
#   MongoNs = each.value.namespace
#   Cluster = var.Cluster
#   Color = local.inactiveCluster
#   providers = {
#     kubernetes = kubernetes.kubernetes-inactive
#   }
# }
module "mongod-restore" {
  for_each = var.Settings.clusters[var.Cluster].mongo
  source = "../../terraform-modules/k8s-vault-mongo-restore"
  BackupSettings = each.value.mongoMigrateSettings
  BackupBucket = each.value.backupBucket
  MongoNs = each.value.namespace
  Cluster = var.Cluster
  Color = local.activeCluster
  # depends_on = [module.mongod-backup ]
}
