
locals {
  buckets = [
    "maid",
    "magescanner"
  ]
}


data "google_project" "current" {}

#Create the storage bucket
resource "google_storage_bucket" "minio_buckets" {
  count         = length(local.buckets)
  name          = "minio-${element(local.buckets, count.index)}-${data.google_project.current.project_id}"
  project       = data.google_project.current.project_id
  force_destroy = true
  storage_class = "STANDARD"
  # storage_class = "MULTI_REGIONAL"

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
