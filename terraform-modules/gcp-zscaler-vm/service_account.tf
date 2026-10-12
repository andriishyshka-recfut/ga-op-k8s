resource "google_service_account" "vm" {
  project      = local.gcp_project
  account_id   = local.service_account_id
  display_name = coalesce(local.service_account_display_name, "${local.name} service account")
}

resource "google_service_account_iam_member" "self_token_creator" {
  service_account_id = google_service_account.vm.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_project_iam_member" "vm_service_account" {
  count = length(local.service_account_iam_roles)

  project = local.gcp_project
  role    = element(local.service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "time_rotating" "vm_service_account_key" {
  count = local.service_account_key_rotation_days != null ? 1 : 0

  rotation_days = local.service_account_key_rotation_days
}

resource "google_service_account_key" "vm" {
  count = local.create_service_account_key ? 1 : 0

  service_account_id = google_service_account.vm.name

  keepers = local.service_account_key_rotation_days != null ? {
    rotation = time_rotating.vm_service_account_key[0].id
  } : {}

  lifecycle {
    create_before_destroy = true
  }
}
