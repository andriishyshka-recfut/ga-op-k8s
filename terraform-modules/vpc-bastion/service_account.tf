
locals {
  adminEnabledApis = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "oslogin.googleapis.com",
    "cloudkms.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    // required for consent screen creation clientauthconfig.brands.create
    // https://cloud.google.com/iap/docs/programmatic-oauth-clients#before-you-begin
    "iap.googleapis.com",
  ]
  serviceAccountIamRoles = [

    "roles/compute.admin",
    "roles/compute.networkAdmin",
    "roles/container.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin",
    "roles/storage.objectAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/compute.instanceAdmin",
    "roles/compute.instanceAdmin.v1",
    "roles/dns.admin",
    "roles/compute.osAdminLogin",
    "roles/cloudkms.admin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/editor",
  ]
}
resource "google_project_service" "enabled_apis" {
  for_each = toset(local.adminEnabledApis)
  service  = each.value
  //disable_dependent_services = false
  //disable_on_destroy         = true
}


resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Runner Service Account"
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_iam_member" "service_account" {
  project = var.Settings.gcpProject
  count  = length(local.serviceAccountIamRoles)
  role   = element(local.serviceAccountIamRoles, count.index)
  member = format("serviceAccount:%s", google_service_account.terraform.email)
  depends_on = [
    google_project_service.enabled_apis
  ]
  lifecycle {
    prevent_destroy = true
  }

}
