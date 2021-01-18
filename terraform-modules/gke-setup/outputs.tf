

locals {
  gkeClusterConnectionSettings = {
    HOST                   = "https://${google_container_cluster.cluster.endpoint}"
    API_KEY                = data.google_client_config.default.access_token
    CLUSTER_CA_CERTIFICATE = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate, )
  }
}

output "GkeClusterConnectionSettings" {
  value = local.gkeClusterConnectionSettings
}
