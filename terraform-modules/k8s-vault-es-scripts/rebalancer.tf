data "kubernetes_secret" "rebalancer_elasticsearch_credentials" {
  for_each    = var.rebalancer
  metadata {
    name      = "elastic-credentials"
    namespace = try(each.value.elasticsearch_namespace, local.elasticsearch_namespace)
  }
}

resource "kubernetes_secret" "rebalancer_elasticsearch_credentials" {
  for_each    = var.rebalancer
  metadata {
    name      = "${each.key}-rebalancer-elastic-credentials"
    namespace = try(each.value.namespace, local.namespace)
  }
  data        = data.kubernetes_secret.rebalancer_elasticsearch_credentials[each.key].data
}

data "kubernetes_secret" "rebalancer_elasticsearch_certs" {
  for_each    = var.rebalancer
  metadata {
    name      = "elastic-https-certs"
    namespace = try(each.value.elasticsearch_namespace, local.elasticsearch_namespace)
  }
}

resource "kubernetes_secret" "rebalancer_elasticsearch_certs" {
  for_each    = var.rebalancer
  metadata {
    name      = "${each.key}-rebalancer-elastic-https-certs"
    namespace = try(each.value.namespace, local.namespace)
  }
  data        = data.kubernetes_secret.rebalancer_elasticsearch_certs[each.key].data
}


resource "kubernetes_deployment_v1" "elasticsearch_rebalancer" {
  for_each    = var.rebalancer
  metadata {
    name      = "${each.key}-rebalancer"
    namespace = try(each.value.namespace, local.namespace)
    labels = {
      app     = "${each.key}-rebalancer"
    }
  }

  spec {
    replicas = 0

    selector {
      match_labels = {
        app = "${each.key}-rebalancer"
      }
    }

    template {
      metadata {
        labels = {
          app     = "${each.key}-rebalancer"
        }
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }

      spec {
        container {
          image = "harbor.regemini.io/op/rebalancer:${var.rebalancer_version}"
          name  = "rebalancer"
          command = ["/bin/sh", "-c"]
          args = ["sleep infinity"]
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "100Mi"
            }
          }
          env {
            name = "ES_PASS"
            value_from {
              secret_key_ref {
                key  = "elastic"
                name = kubernetes_secret.rebalancer_elasticsearch_credentials[each.key].metadata.0.name
              }
            }
          }
          volume_mount {
            mount_path = "/opt/rebalance/certs"
            name       = "elasticsearch-certs"
          }
        }
        image_pull_secrets {
          name = "harbor"
        }
        volume {
          name = "elasticsearch-certs"
          projected {
            sources {
              secret {
                name = "${each.key}-rebalancer-elastic-https-certs"
                items {
                  key = "ca.crt"
                  path = "ca.crt"
                  mode = "0600"
                }
                items {
                  key = "tls.crt"
                  path = "tls.crt"
                  mode = "0600"
                }
                items {
                  key = "tls.key"
                  path = "tls.key"
                  mode = "0600"
                }
              }
            }
          }
        }
      }
    }
  }
}
