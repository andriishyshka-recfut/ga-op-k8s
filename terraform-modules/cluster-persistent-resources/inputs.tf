
data "google_project" "current" {}

variable "Settings" {}

variable "Cluster" {}

locals {
  vaultBucketName       = var.Settings.clusters[var.Cluster].persistent_resources.vault_bucket_name
  vaultKeyName          = var.Settings.clusters[var.Cluster].persistent_resources.vault_key_name
  esBackupBucket        = var.Settings.clusters[var.Cluster].persistent_resources.es_backup_bucket
  vaultServiceAccountId = var.Settings.clusters[var.Cluster].persistent_resources.vault_service_account_id
}
