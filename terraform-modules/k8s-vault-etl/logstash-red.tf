resource "kubernetes_service" "logstash_1_service" {
  count = var.Cluster == "production" ? 1 : 0
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
      port        = 9600
      target_port = 9600
    }
  }
}
resource "kubernetes_service" "logstash_2_service" {
  count = var.Cluster == "production" ? 1 : 0
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
      port        = 9600
      target_port = 9600
    }
  }
}

resource "kubernetes_endpoints" "logstash_1_endpoint" {
  count = var.Cluster == "production" ? 1 : 0
  metadata {
    name      = kubernetes_service.logstash_1_service[0].metadata[0].name
    namespace = local.namespace
    labels = {
      "kubernetes.io/service-name" = kubernetes_service.logstash_1_service[0].metadata[0].name
    }
  }

  subset {
    address {
      ip = var.Settings.internal_static_ips.logstash-1-red.ip
    }

    port {
      name     = "logstash"
      port     = 9600
      protocol = "TCP"
    }
  }
}

resource "kubernetes_endpoints" "logstash_2_endpoint" {
  count = var.Cluster == "production" ? 1 : 0
  metadata {
    name      = kubernetes_service.logstash_2_service[0].metadata[0].name
    namespace = local.namespace
    labels = {
      "kubernetes.io/service-name" = kubernetes_service.logstash_2_service[0].metadata[0].name
    }
  }

  subset {
    address {
      ip = var.Settings.internal_static_ips.logstash-2-red.ip
    }

    port {
      name     = "logstash"
      port     = 9600
      protocol = "TCP"
    }
  }
}