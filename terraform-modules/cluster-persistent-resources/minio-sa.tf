
resource "google_service_account" "minio_service_account" {
  account_id   = local.minioServiceAccountId
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
  project = data.google_project.current.id

}
