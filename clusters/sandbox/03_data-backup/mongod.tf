module "mongod-backup" {
  source = "../../../terraform-modules/k8s-vault-mongo-backup"
  BackupSettings = var.Settings.clusters["sandbox"].mongoBackupSettings
  Cluster = var.Cluster
  Color = local.inactiveCluster
  providers = {
    kubernetes = kubernetes.kubernetes-inactive
  }
}
module "mongod-restore" {
  source = "../../../terraform-modules/k8s-vault-mongo-restore"
  BackupSettings = var.Settings.clusters["sandbox"].mongoBackupSettings
  Cluster = var.Cluster
  Color = local.activeCluster
  depends_on = [module.mongod-backup ]
}
