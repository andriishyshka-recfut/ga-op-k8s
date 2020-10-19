
data "google_project" "current" {}

variable "settings" {}

variable "cluster" {}

locals {
  vault_bucket_name        = var.settings.clusters[var.cluster].persistent_resources.vault_bucket_name
  vault_key_name           = var.settings.clusters[var.cluster].persistent_resources.vault_key_name
  es_backup_bucket         = var.settings.clusters[var.cluster].persistent_resources.es_backup_bucket
  vault_service_account_id = var.settings.clusters[var.cluster].persistent_resources.vault_service_account_id
}
