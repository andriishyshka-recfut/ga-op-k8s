
module "mongod-backup" {
  source = "../../terraform-modules/k8s-vault-mongo-backup"
  BackupSettings = var.Settings.clusters[var.Cluster].mongo.auth.mongoMigrateSettings
  BackupBucket = var.Settings.clusters[var.Cluster].mongo.auth.backupBucket
  MongoNs = var.Settings.clusters[var.Cluster].mongo.auth.namespace
  Cluster = var.Cluster
  Color = local.inactiveCluster
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}
module "mongod-restore" {
  count = local.prod_runs
  source = "../../terraform-modules/k8s-vault-mongo-restore"
  BackupSettings = var.Settings.clusters[var.Cluster].mongo.auth.mongoMigrateSettings
  BackupBucket = var.Settings.clusters[var.Cluster].mongo.auth.backupBucket
  MongoNs = var.Settings.clusters[var.Cluster].mongo.auth.namespace
  Cluster = var.Cluster
  Color = local.activeCluster
  depends_on = [module.mongod-backup ]
}