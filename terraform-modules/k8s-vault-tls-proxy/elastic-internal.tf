resource "kubernetes_config_map" "haproxy_elastic_configmap" {
  for_each = toset(var.ElasticProxyNS)
  metadata {
    name      = "elastic-internal-proxy-config"
    namespace = each.key
  }
  data = {
    "haproxy.cfg" = <<EOF
frontend auth
  mode  http
  bind  :9200
  default_backend elastic
backend elastic
  mode  http
  server srv1 $SERVICE_HOST:$SERVICE_PORT ssl verify required ca-file /usr/local/etc/haproxy/ssl/ca.crt crt /usr/local/etc/haproxy/ssl/tls.crt
EOF
  }
}

resource "kubernetes_deployment" "elastic_internal_proxy" {
  for_each = toset(var.ElasticProxyNS)
  metadata {
    name      = "elstic-internal-proxy"
    namespace = each.key
    labels = {
      app = "elstic-internal-proxy"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "elastic-internal-proxy"
      }
    }
    template {
      metadata {
        labels = {
          app = "elastic-internal-proxy"
        }
      }
      spec {
        volume {
          name = "haproxy-config"
          config_map {
            name = "elastic-internal-proxy-config"
          }
        }
        volume {
          name = "haproxy-ssl"
          secret {
            secret_name = "${each.key}-es-cert"
          }
        }
        container {
          image = "haproxy:alpine"
          name  = "elastic-proxy"
          volume_mount {
            name       = "haproxy-config"
            mount_path = "/usr/local/etc/haproxy"
            read_only  = true
          }
          volume_mount {
            name       = "haproxy-ssl"
            mount_path = "/usr/local/etc/haproxy/ssl"
            read_only  = true
          }
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          port {
            protocol       = "TCP"
            container_port = 9200
          }
          env {
            name  = "SERVICE_HOST"
            value = "${each.key}-es-http"
          }
          env {
            name  = "SERVICE_PORT"
            value = 9200
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "elastic_internal_proxy" {
  for_each = toset(var.ElasticProxyNS)
  metadata {
    name      = "elastic-internal-proxy"
    namespace = each.key
  }
  spec {
    selector = {
      app = "elastic-intrnal-proxy"
    }
    port {
      port        = 9200
      target_port = 9200
    }
  }
}
