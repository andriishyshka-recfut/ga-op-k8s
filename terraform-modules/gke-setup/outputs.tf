output "gke_cluster_endpoint" {
  value = "https://${google_container_cluster.cluster.endpoint}"
}
output "gke_bearer_token" {
  value = data.google_client_config.default.access_token
}
output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate,)
}
