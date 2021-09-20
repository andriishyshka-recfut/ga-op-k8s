resource "kubernetes_service" "minio_console" {
  metadata {
    name = "minio-console"
    namespace = local.minioNs
  }
  spec {
    selector = {
      app = "minio"
      release = "minio"
    }
    port {
      port        = 9001
      target_port = 9001
    }

    type = "ClusterIP"
  }
}
