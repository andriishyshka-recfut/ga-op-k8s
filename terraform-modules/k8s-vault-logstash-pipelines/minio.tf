resource "kubernetes_service" "minio_service" {
  metadata {
    name      = "minio"
    namespace = local.namespace
  }
  spec {
    cluster_ip       = "None"
    session_affinity = "None"
    port {
      name        = "minio"
      protocol    = "TCP"
      port        = 9000
      target_port = 9000
    }
  }
}

resource "kubernetes_endpoints" "minio_endpoint" {
  count = var.Cluster == "production" ? 1 : 0
  metadata {
    name      = kubernetes_service.minio_service.metadata[0].name
    namespace = local.namespace
    labels = {
      "kubernetes.io/service-name" = kubernetes_service.minio_service.metadata[0].name
    }
  }

  subset {
    address {
      ip = var.Settings.internal_static_ips.minio.ip
    }

    port {
      name     = "minio"
      port     = 9000
      protocol = "TCP"
    }
  }
}