/*
resource "kubernetes_config_map" "haproxy_elastic_configmap" {
  for_each = var.ElasticProxyNS
  metadata {
    name      = "elastic-internal-proxy-config"
    namespace = each.key
  }
  data = {
    "haproxy.cfg" = <<EOF
defaults
  retries 3
  option  redispatch
  timeout client 30s
  timeout connect 4s
  timeout server 30s
  timeout http-request 10s
  timeout http-keep-alive 2s
  timeout queue 5s
  timeout tunnel 2m
  timeout client-fin 1s
  timeout server-fin 1s
frontend auth
  mode  tcp
  bind  :9200
  default_backend elastic
backend elastic
  mode  tcp
  server srv0 ${each.value}-es-master-0.${each.value}-es-master:9200 ssl verify required ca-file /usr/local/etc/haproxy/ssl/ca.crt check
  server srv1 ${each.value}-es-master-1.${each.value}-es-master:9200 ssl verify required ca-file /usr/local/etc/haproxy/ssl/ca.crt check
  server srv2 ${each.value}-es-master-2.${each.value}-es-master:9200 ssl verify required ca-file /usr/local/etc/haproxy/ssl/ca.crt check
EOF
  }
}

resource "kubernetes_deployment" "elastic_internal_proxy" {
  for_each = var.ElasticProxyNS
  metadata {
    name      = "elastic-internal-proxy"
    namespace = each.key
    labels = {
      app = "elastic-internal-proxy"
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
            secret_name = "${each.value}-es-cert"
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
            value = "${each.value}-es-master"
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
/*
resource "kubernetes_service" "elastic_internal_proxy" {
  for_each = var.ElasticProxyNS
  metadata {
    name      = "elastic-internal-proxy"
    namespace = each.key
  }
  spec {
    selector = {
      app = "elastic-internal-proxy"
    }
    port {
      port        = 9200
      target_port = 9200
    }
  }
}
*/