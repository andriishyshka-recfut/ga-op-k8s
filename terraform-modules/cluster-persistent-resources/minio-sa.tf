
resource "google_service_account" "minio_service_account" {
  account_id   = "minio-sa"
  display_name = "Minio Service Account"
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_iam_member" "minio_service_account_member" {
  role   = "roles/storage.admin"
  member = format("serviceAccount:%s", google_service_account.minio_service_account.email)
  lifecycle {
    prevent_destroy = true
  }

}
resource "google_service_account_key" "minio_key" {
  service_account_id = google_service_account.minio_service_account.id
}
