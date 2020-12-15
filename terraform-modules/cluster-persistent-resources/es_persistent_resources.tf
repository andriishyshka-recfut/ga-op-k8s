
#Create the storage bucket
resource "google_storage_bucket" "elastic_snapshots" {
  name          = local.esBackupBucket
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

# resource "random_id" "es_name" {
#   prefix      = "elastic-"
#   byte_length = "7"
# }

resource "google_service_account" "es_server" {
  account_id   = "elastic-backup"
  display_name = "ES Server"
  //project      = data.google_project.vault.project_id
}

variable "EsServiceAccountIamRoles" {
  type = list(string)
  default = [
    "roles/storage.objectAdmin",
    "roles/storage.admin"
  ]
  description = "List of storage bucket roles."
}
# Add the service account to the project
resource "google_project_iam_member" "es_service_account" {
  count   = length(var.EsServiceAccountIamRoles)
  project = data.google_project.current.project_id
  role    = element(var.EsServiceAccountIamRoles, count.index)
  member  = "serviceAccount:${google_service_account.es_server.email}"
}


resource "google_service_account_key" "es_key" {
  service_account_id = google_service_account.es_server.name
}
