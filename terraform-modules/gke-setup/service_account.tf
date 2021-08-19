
locals {
  serviceAccountIamRoles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    # "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    # "roles/container.admin"
  ]
}



resource "google_service_account" "gke_sa" {
  account_id   = "k8s-${var.Cluster}-${var.Color}-sa"
  display_name = "${var.Cluster} GKE Security Service Account "
}

resource "google_project_iam_member" "service_account" {
  count  = length(local.serviceAccountIamRoles)
  role   = element(local.serviceAccountIamRoles, count.index)
  member = format("serviceAccount:%s", google_service_account.gke_sa.email)
}
