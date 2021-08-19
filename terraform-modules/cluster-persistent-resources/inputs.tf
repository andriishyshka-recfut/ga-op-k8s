
data "google_project" "current" {}

variable "Settings" {}

variable "Cluster" {}

locals {
  vaultBucketName       = var.Settings.clusters[var.Cluster].persistent_resources.vault_bucket_name
  vaultKeyName          = var.Settings.clusters[var.Cluster].persistent_resources.vault_key_name
  esBackupBucket        = var.Settings.clusters[var.Cluster].persistent_resources.es_backup_bucket
  vaultServiceAccountId = var.Settings.clusters[var.Cluster].persistent_resources.vault_service_account_id
  minioServiceAccountId = var.Settings.clusters[var.Cluster].persistent_resources.minio_service_account_id
  gkeKmsVolumeKey       = var.Settings.clusters[var.Cluster].persistent_resources.gke_kms_volume_key
  gkeRegion             = var.Settings.clusters[var.Cluster].region
}
