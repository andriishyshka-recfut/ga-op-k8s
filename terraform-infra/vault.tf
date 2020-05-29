
provider "google" {
  version = "v3.19.0"
}


# Create the vault service account
resource "google_service_account" "vault-server" {
  account_id   = "vault-server"
  display_name = "Vault Server"
  //project      = data.google_project.vault.project_id
}

variable "vault_service_account_iam_roles" {
  type = list(string)
  default = [
    "roles/storage.legacyBucketReader",
    "roles/storage.objectAdmin",
  ]
  description = "List of storage bucket roles."
}

# Add the service account to the project
resource "google_project_iam_member" "service-account" {
  count   = length(var.vault_service_account_iam_roles)
  project = data.google_project.vault.project_id
  role    = element(var.vault_service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.vault-server.email}"
}


# Create the storage bucket
resource "google_storage_bucket" "vault" {
  name          = "${data.google_project.vault.project_id}-vault-storage"
  project       = data.google_project.vault.project_id
  force_destroy = true
  storage_class = "MULTI_REGIONAL"

  bucket_policy_only = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = 1
    }
  }

}



# This uses a random_id to prevent that from happening.
resource "random_id" "kms_random" {
  prefix      = var.kms_key_ring_prefix
  byte_length = "8"
}


# Create the KMS key ring
resource "google_kms_key_ring" "vault" {
  name     = random_id.kms_random.hex
  location = var.region
  project  = data.google_project.vault.project_id

  depends_on = [google_project_service.service]
}


# Create the crypto key for encrypting init keys
resource "google_kms_crypto_key" "vault-init" {
  name            = var.kms_crypto_key
  key_ring        = google_kms_key_ring.vault.id
  rotation_period = "604800s"
}

# Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "vault-init" {
  crypto_key_id = google_kms_crypto_key.vault-init.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.vault-server.email}"
}
