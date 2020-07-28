
# Create the vault service account
resource "google_service_account" "vault-server" {
  account_id   = "vault-server-${var.settings[var.cluster].color}"
  display_name = "Vault Server"
  //project      = data.google_project.vault.project_id
}

variable "vault_service_account_iam_roles" {
  type = list(string)
  default = [
    "roles/storage.objectAdmin",
  ]
  description = "List of storage bucket roles."
}

# Add the service account to the project
resource "google_project_iam_member" "vault-service-account" {
  count   = length(var.vault_service_account_iam_roles)
  project = data.google_project.current.project_id
  role    = element(var.vault_service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.vault-server.email}"
}


resource "google_service_account_key" "vault-key" {
  service_account_id = google_service_account.vault-server.name
}


variable "vault_service_account_key_iam_roles" {
  type = list(string)
  default = [
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/cloudkms.admin",
  ]
  description = "List of storage bucket roles."
}


# Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "vault-init" {
  count         = length(var.vault_service_account_key_iam_roles)
  crypto_key_id = google_kms_crypto_key.vault-init.id
  role          = element(var.vault_service_account_key_iam_roles, count.index)
  member        = "serviceAccount:${google_service_account.vault-server.email}"
}
