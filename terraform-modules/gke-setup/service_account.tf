
locals {
  serviceAccountIamRoles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    # "roles/container.admin"
  ]
}

data "google_kms_key_ring" "gke_kms_ring" {
  name     = local.gkeKmsVolumeKey
  location = local.gkeRegion
}

data "google_kms_crypto_key" "gke_kms_crypto_key" {
  name     = local.gkeKmsVolumeKey
  key_ring = data.google_kms_key_ring.gke_kms_ring.self_link
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

variable "VaultServiceAccountKeyIamRoles" {
  type = list(string)
  default = [
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
  ]
  description = "List of storage bucket roles."
}


# Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "gke_init" {
  count         = length(var.VaultServiceAccountKeyIamRoles)
  crypto_key_id = data.google_kms_crypto_key.gke_kms_crypto_key.id
  role          = element(var.VaultServiceAccountKeyIamRoles, count.index)
  member        = "serviceAccount:${data.google_compute_default_service_account.default.email}"
  # lifecycle {
  #   prevent_destroy = true
  # }
}
