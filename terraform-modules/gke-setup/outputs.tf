output "gke_cluster_endpoint" {
  value = "https://${google_container_cluster.cluster.endpoint}"
}
output "gke_bearer_token" {
  value = data.google_client_config.default.access_token
}
output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
}




# Use this value to lock before further deployment.
# Terraform 0.13 should support modules depends_on
# Before this we should define a variable in depends_on blocks of separate modules
output "node_pool" {
  value = google_container_node_pool.cluster_preemptible_nodes.id
}
