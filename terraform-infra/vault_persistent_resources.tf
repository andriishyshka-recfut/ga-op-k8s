data "google_project" "vault" {
}

#Create the storage bucket
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

# Generate a random suffix for the KMS keyring. Like projects, key rings names
# must be globally unique within the project. A key ring also cannot be
# destroyed, so deleting and re-creating a key ring will fail.
#
# This uses a random_id to prevent that from happening.
resource "random_id" "kms_random" {
  prefix      = "vault"
  byte_length = "7"
}


# Create the KMS key ring
resource "google_kms_key_ring" "vault" {
  name     = "vault"
  # location = var.region
  location = "global"
  project  = data.google_project.vault.project_id

}


# Create the crypto key for encrypting init keys
resource "google_kms_crypto_key" "vault-init" {
  name            = random_id.kms_random.hex
  key_ring        = google_kms_key_ring.vault.id
  rotation_period = "86400s"
}
