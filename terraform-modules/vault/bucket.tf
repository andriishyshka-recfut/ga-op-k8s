
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
