variable "service_account_iam_roles" {
  type = list

  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
  description = <<-EOF
  List of the default IAM roles to attach to the service account on the
  GKE Nodes.
  EOF
}

resource "google_service_account" "gke-sa" {
  account_id   = "k8s-${var.cluster}-sa"
  display_name = "${var.cluster} GKE Security Service Account "
}

variable "service_account_iam_roles" {
  type = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.legacyBucketReader",
    "roles/storage.objectAdmin"
  ]
  description = "List of IAM roles to assign to the service account."
}



resource "google_project_iam_member" "service-account" {
  count   = length(var.service_account_iam_roles)
  role    = element(var.service_account_iam_roles, count.index)
  member  = format("serviceAccount:%s", google_service_account.gke-sa.email)
}

variable "project_services" {
  type = list(string)
  default = [
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
  description = "List of services to enable on the project."
}


# Enable required services on the project
resource "google_project_service" "service" {
  count   = length(var.project_services)
  project = data.google_project.vault.project_id
  service = element(var.project_services, count.index)

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}
