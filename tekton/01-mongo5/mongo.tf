module "mongo" {  
  source         = "../../terraform-modules/k8s-vault-mongo"
  CredsPath      = var.Settings.clusters[var.Cluster].mongo["mongo5"].vaultPath
  MongoNs        = var.Settings.clusters[var.Cluster].mongo["mongo5"].namespace
  BackupSettings = var.Settings.clusters[var.Cluster].mongo["mongo5"].mongoMigrateSettings
  BackupBucket   = var.Settings.clusters[var.Cluster].mongo["mongo5"].backupBucket
  VolumeSize     = var.Settings.clusters[var.Cluster].mongo["mongo5"].volumeSize
  Replicas       = var.Settings.clusters[var.Cluster].mongo["mongo5"].replicas
  Cluster        = var.Cluster
  Color          = var.Color
  ImageTag       = var.Settings.clusters[var.Cluster].mongo["mongo5"].imageTag
  Repository     = var.Settings.clusters[var.Cluster].mongo["mongo5"].repository
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
}
