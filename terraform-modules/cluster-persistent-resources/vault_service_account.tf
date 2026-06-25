
# Create the vault service account
resource "google_service_account" "vault_server" {
  account_id   = local.vaultServiceAccountId
  display_name = "Vault Server"
  //project      = data.google_project.vault.project_id
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# Add the service account roles to the project
resource "google_project_iam_member" "vault_service_account" {
  count   = length(local.vaultServiceAccountIamRoles)
  project = data.google_project.current.project_id
  role    = element(local.vaultServiceAccountIamRoles, count.index)
  member  = "serviceAccount:${google_service_account.vault_server.email}"
  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "google_service_account_key" "vault_key" {
  service_account_id = google_service_account.vault_server.name
}

resource "google_service_account_iam_member" "vault_service_account_self" {
  count = length(local.vaultServiceAccountSelfIamRoles)

  service_account_id = google_service_account.vault_server.name
  role               = element(local.vaultServiceAccountSelfIamRoles, count.index)
  member             = "serviceAccount:${google_service_account.vault_server.email}"
}

# Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "vault_init" {
  count         = length(local.vaultServiceAccountKeyIamRoles)
  crypto_key_id = google_kms_crypto_key.vault_unseal_key.id
  role          = element(local.vaultServiceAccountKeyIamRoles, count.index)
  member        = "serviceAccount:${google_service_account.vault_server.email}"
  # lifecycle {
  #   prevent_destroy = true
  # }
}
