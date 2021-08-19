resource "google_kms_key_ring" "keyring" {
  name     = "keyring-gke-volumes"
  location = "global"
}

resource "google_kms_crypto_key" "gke_kms_volume_key" {
  name            = "gke_kms_volume_key"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "100000s"

  lifecycle {
    prevent_destroy = true
  }
}
