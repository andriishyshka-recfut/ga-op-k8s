resource "google_kms_key_ring" "keyring" {
  name     = local.gkeKmsVolumeKey
  location = local.gkeRegion
}

resource "google_kms_crypto_key" "gke_kms_volume_key" {
  name            = local.gkeKmsVolumeKey
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "3000000s"

  lifecycle {
    prevent_destroy = true
  }
}




# Grant compute service account access to the key
# https://github.com/hashicorp/terraform-provider-google/issues/5103#issuecomment-563402407
# https://cloud.google.com/kubernetes-engine/docs/how-to/using-cmek#grant_permission
resource "google_kms_crypto_key_iam_member" "gke_init" {

  crypto_key_id = google_kms_crypto_key.gke_kms_volume_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"
  # lifecycle {
  #   prevent_destroy = true
  # }
}
