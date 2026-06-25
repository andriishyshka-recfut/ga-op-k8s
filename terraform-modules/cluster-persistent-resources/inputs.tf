
data "google_project" "current" {}

variable "Settings" {}

variable "Cluster" {}

locals {
  vaultBucketName       = var.Settings.clusters[var.Cluster].persistent_resources.vault_bucket_name
  vaultKeyName          = var.Settings.clusters[var.Cluster].persistent_resources.vault_key_name
  vaultServiceAccountId = var.Settings.clusters[var.Cluster].persistent_resources.vault_service_account_id
  vaultServiceAccountIamRoles = try(
    var.Settings.clusters[var.Cluster].persistent_resources.vault_service_account_iam_roles,
    [
      "roles/storage.objectAdmin",
      "roles/compute.viewer",
      "roles/iam.serviceAccountViewer",
    ]
  )
  vaultServiceAccountKeyIamRoles = try(
    var.Settings.clusters[var.Cluster].persistent_resources.vault_service_account_key_iam_roles,
    [
      "roles/cloudkms.cryptoKeyEncrypterDecrypter",
      "roles/cloudkms.admin",
    ]
  )
  vaultServiceAccountSelfIamRoles = try(
    var.Settings.clusters[var.Cluster].persistent_resources.vault_service_account_self_iam_roles,
    []
  )
  minioServiceAccountId = var.Settings.clusters[var.Cluster].persistent_resources.minio_service_account_id
  gkeKmsVolumeKey       = var.Settings.clusters[var.Cluster].persistent_resources.gke_kms_volume_key
  gkeRegion             = var.Settings.clusters[var.Cluster].region
}


data "google_compute_network" "vpc" {
  name = var.Settings.vpc_name
}
