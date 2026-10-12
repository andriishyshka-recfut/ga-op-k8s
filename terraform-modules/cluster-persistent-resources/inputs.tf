
data "google_project" "current" {}
variable "Settings" {}
variable "Cluster" {}
variable "destination_ranges" {}
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
  ip_count     = lookup(var.Settings, "nat_ip_count", 0)
  nat_ips      = [for count_name in range(0, local.ip_count, 1) : data.google_compute_address.ip_address[count_name].address]
  nat_ip_links = { for ip in data.google_compute_address.ip_address : ip.address => ip.self_link }
  rule_ips     = toset(flatten([for nat in values(lookup(var.Settings, "nat", {})) : try(nat.ext_ip, [])]))
  default_ips  = setsubtract(toset(local.nat_ips), local.rule_ips)
}

data "google_compute_network" "vpc" {
  name = var.Settings.vpc_name
}
