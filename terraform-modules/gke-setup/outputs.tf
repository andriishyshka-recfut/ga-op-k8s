# output "gke_cluster_endpoint" {
#   value = "https://${google_container_cluster.cluster.endpoint}"
# }
# output "gke_bearer_token" {
#   value = data.google_client_config.default.access_token
# }
# output "cluster_ca_certificate" {
#   value = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
# }
#


locals {
  gke_cluster_connection_settings = {
    # gke_cluster_endpoint   = "https://${google_container_cluster.cluster.endpoint}"
    # gke_bearer_token       = data.google_client_config.default.access_token
    # cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
    HOST                   = "https://${google_container_cluster.cluster.endpoint}"
    API_KEY                = data.google_client_config.default.access_token
    CLUSTER_CA_CERTIFICATE = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
  }
}

output "gke_cluster_connection_settings" {
  value = local.gke_cluster_connection_settings
}
