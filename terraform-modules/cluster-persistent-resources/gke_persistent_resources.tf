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
