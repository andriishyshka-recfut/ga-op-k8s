resource "kubernetes_config_map" "minio_endpoints" {
  for_each = local.minio_endpoints
  metadata {
    name      = "minio-endpoint-${each.key}"
    namespace = local.namespace
  }

  data = {
    name = each.value.var_name
    path = each.value.path
  }
}
