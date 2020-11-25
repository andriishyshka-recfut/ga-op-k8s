variable "service_account_iam_roles" {
  type = list

  default = [
    "roles/storage.admin",
  ]
  description = <<-EOF
  List of the default IAM roles to attach to the service account on the
  GKE Nodes.
  EOF
}

resource "google_service_account" "minio" {
  account_id   = "minio-sa"
  display_name = "Minio Service Account"
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "google_project_iam_member" "service-account" {
  count  = length(var.service_account_iam_roles)
  role   = element(var.service_account_iam_roles, count.index)
  member = format("serviceAccount:%s", google_service_account.minio.email)
  # lifecycle {
  #   prevent_destroy = true
  # }

}
resource "google_service_account_key" "minio-key" {
  service_account_id = google_service_account.minio.id
}
