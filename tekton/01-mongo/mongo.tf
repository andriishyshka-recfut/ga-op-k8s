module "mongo" {
  for_each       = var.Settings.clusters[var.Cluster].mongo
  source         = "../../terraform-modules/k8s-vault-mongo"
  CredsPath      = each.value.vaultPath
  MongoNs        = each.value.namespace
  BackupSettings = each.value.mongoMigrateSettings
  BackupBucket   = each.value.backupBucket
  VolumeSize     = each.value.volumeSize
  Replicas       = each.value.replicas
  Cluster        = var.Cluster
  Color          = var.Color
  Settings       = var.Settings
  ImageTag       = each.value.imageTag
  Repository     = each.value.repository
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
