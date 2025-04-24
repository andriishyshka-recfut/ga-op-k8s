resource "kubernetes_service" "logstash_1_service" {
  metadata {
    name      = "logstash-1"
    namespace = local.namespace
  }
  spec {
    cluster_ip       = "None"
    session_affinity = "None"
    port {
      name        = "logstash"
      protocol    = "TCP"
      port        = 9601
      target_port = 9601
    }
  }
}
resource "kubernetes_service" "logstash_2_service" {
  metadata {
    name      = "logstash-2"
    namespace = local.namespace
  }
  spec {
    cluster_ip       = "None"
    session_affinity = "None"
    port {
      name        = "logstash"
      protocol    = "TCP"
      port        = 9602
      target_port = 9602
    }
  }
}

resource "kubernetes_endpoints" "logstash_1_endpoint" {
  metadata {
    name      = kubernetes_service.logstash_1_service.metadata[0].name
    namespace = local.namespace
    labels = {
      "kubernetes.io/service-name" = kubernetes_service.logstash_1_service.metadata[0].name
    }
  }

  subset {
    address {
      ip = var.Settings.internal_static_ips.logstash-1-red.ip
    }

    port {
      name     = "logstash"
      port     = 9601
      protocol = "TCP"
    }
  }
}

resource "kubernetes_endpoints" "logstash_2_endpoint" {
  metadata {
    name      = kubernetes_service.logstash_2_service.metadata[0].name
    namespace = local.namespace
    labels = {
      "kubernetes.io/service-name" = kubernetes_service.logstash_2_service.metadata[0].name
    }
  }

  subset {
    address {
      ip = var.Settings.internal_static_ips.logstash-2-red.ip
    }

    port {
      name     = "logstash"
      port     = 9602
      protocol = "TCP"
    }
  }
}