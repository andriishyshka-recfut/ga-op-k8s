
# Create the vault service account
resource "google_service_account" "vault_server" {
  account_id   = local.vaultServiceAccountId
  display_name = "Vault Server"
  //project      = data.google_project.vault.project_id
  lifecycle {
    prevent_destroy = true
  }
}

variable "VaultServiceAccountIamRoles" {
  type = list(string)
  default = [
    "roles/storage.objectAdmin",
  ]
  description = "List of storage bucket roles."
}

# Add the service account to the project
resource "google_project_iam_member" "vault_service_account" {
  count   = length(var.VaultServiceAccountIamRoles)
  project = data.google_project.current.project_id
  role    = element(var.VaultServiceAccountIamRoles, count.index)
  member  = "serviceAccount:${google_service_account.vault_server.email}"
  lifecycle {
    prevent_destroy = true
  }
}


resource "google_service_account_key" "vault_key" {
  service_account_id = google_service_account.vault_server.name
}


variable "VaultServiceAccountKeyIamRoles" {
  type = list(string)
  default = [
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/cloudkms.admin",
  ]
  description = "List of storage bucket roles."
}


# Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "vault_init" {
  count         = length(var.VaultServiceAccountKeyIamRoles)
  crypto_key_id = google_kms_crypto_key.vault_unseal_key.id
  role          = element(var.VaultServiceAccountKeyIamRoles, count.index)
  member        = "serviceAccount:${google_service_account.vault_server.email}"
  lifecycle {
    prevent_destroy = true
  }
}
