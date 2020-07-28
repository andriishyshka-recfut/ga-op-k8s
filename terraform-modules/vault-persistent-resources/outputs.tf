
locals {
  vault_resources = {
    project           = data.google_project.current.project_id
    key_ring          = google_kms_key_ring.vault.name
    crypto_key        = google_kms_crypto_key.vault-init.name
    bucket            = google_storage_bucket.vault.name
    vault_sa_priv_key = base64decode(google_service_account_key.vault-key.private_key)
  }
}
output "vault_resources" {
  value = local.vault_resources
}
