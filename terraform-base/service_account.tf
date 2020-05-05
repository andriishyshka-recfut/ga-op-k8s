
locals {
  admin_enabled_apis = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com"

    ]
  }
resource "google_project_service" "enabled-apis" {
  for_each = toset(local.admin_enabled_apis)
  service  = each.value
  disable_dependent_services = false
  disable_on_destroy         = true
}

variable "service_account_iam_roles" {
  type = list

  default = [
    "roles/compute.admin",
    "roles/compute.networkAdmin",
    "roles/container.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin",
    "roles/storage.objectAdmin",
    "roles/serviceusage.serviceUsageAdmin"
  ]
  description = <<-EOF
  List of the default IAM roles to attach to the service account on the
  GKE Nodes.
  EOF
}

resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Runner Service Account"
}

resource "google_project_iam_member" "service-account" {
  count   = length(var.service_account_iam_roles)
  role    = element(var.service_account_iam_roles, count.index)
  member  = format("serviceAccount:%s", google_service_account.terraform.email)
  depends_on = [
    google_project_service.enabled-apis
  ]
}
