resource "kubernetes_config_map" "minio_endpoints" {
  metadata {
    name = "minio-endpoints"
    namespace = local.namespace
  }

  data = {
    endpoints = local.minio_endpoints
  }
}
