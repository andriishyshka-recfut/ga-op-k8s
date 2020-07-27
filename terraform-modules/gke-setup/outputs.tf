output "gke_cluster_endpoint" {
  value = "https://${google_container_cluster.cluster.endpoint}"
}
output "gke_bearer_token" {
  value = data.google_client_config.default.access_token
}
output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
}



locals {
  vault_resources = {
    project           = data.google_project.current.project_id
    key_ring          = google_kms_key_ring.vault.name
    crypto_key        = google_kms_crypto_key.vault-init.name
    bucket            = google_storage_bucket.vault.name
    vault_sa_priv_key = base64decode(google_service_account_key.vault-key.private_key)
  }
}
output "vault_resources" {
  value = local.vault_resources
}

# Use this value to lock before further deployment.
# Terraform 0.13 should support modules depends_on
# Before this we should define a variable in depends_on blocks of separate modules
output "node_pool" {
  value = google_container_node_pool.cluster_preemptible_nodes.id
}
