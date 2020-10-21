provider "google" {
  # version = "v3.19.0"
}

data "google_project" "current" {}

#Create the storage bucket
resource "google_storage_bucket" "elastic-snapshots" {
  name          = "harbor-backet-${data.google_project.current.project_id}"
  project       = data.google_project.current.project_id
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

# data "google_service_account" "vault-sa" {
#   account_id = "vault-sandbox"
# }
#
# resource "google_service_account_key" "harbor-key" {
#   service_account_id = data.google_service_account.vault-sa.name
# }


# resource "kubernetes_secret" "gcs-credentials" {
#   metadata {
#     name      = "gcs-credentials"
#     namespace = "harbor"
#   }
#
#   data = {
#     "gcs.client.credentials_file" = base64decode(google_service_account_key.harbor-key.private_key)
#   }
#
# }
