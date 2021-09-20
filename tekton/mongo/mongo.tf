

module "mongo" {
  for_each = var.Settings.clusters[var.Cluster].mongo
  source              = "../../terraform-modules/k8s-vault-mongo"
  CredsPath           = each.value.vaultPath
  MongoNs = each.value.namespace
  BackupBucket= each.value.backupBucket
  VolumeSize = each.value.volumeSize
  Replicas = each.value.replicas
}
