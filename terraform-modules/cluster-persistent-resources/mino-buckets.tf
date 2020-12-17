
locals {
  buckets = [
    "maid",
    "magescanner"
  ]
}



#Create the storage bucket
resource "google_storage_bucket" "minio_buckets" {
  count         = length(local.buckets)
  name          = "minio-${element(local.buckets, count.index)}-${data.google_project.current.project_id}"
  project       = data.google_project.current.project_id
  force_destroy = true
  storage_class = "STANDARD"


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

resource "google_storage_bucket" "minio_autoexpire_bucket" {
  name          = "minio-xdebug-${data.google_project.current.project_id}"
  project       = data.google_project.current.project_id
  force_destroy = true
  storage_class = "STANDARD"
  # storage_class = "MULTI_REGIONAL"


  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = 7
    }
  }
}
