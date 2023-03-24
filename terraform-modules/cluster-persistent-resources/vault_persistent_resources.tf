# Create the KMS key ring
resource "google_kms_key_ring" "vault" {
  name = local.vaultKeyName
  # location = var.region
  location = "global"
  project  = data.google_project.current.project_id

  lifecycle {
    prevent_destroy = true
  }
}


# Create the crypto key for encrypting init keys
resource "google_kms_crypto_key" "vault_unseal_key" {
  name                          = local.vaultKeyName
  key_ring                      = google_kms_key_ring.vault.id
  rotation_period               = "8640000s"
  skip_initial_version_creation = false
  lifecycle {
    prevent_destroy = true
  }
}
