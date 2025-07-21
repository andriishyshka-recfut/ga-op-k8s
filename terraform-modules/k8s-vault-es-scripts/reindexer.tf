data "kubernetes_secret" "reindexer_elasticsearch_credentials" {
  for_each    = var.reindexer
  metadata {
    name      = "elastic-credentials"
    namespace = try(each.value.elasticsearch_namespace, local.elasticsearch_namespace)
  }
}

resource "kubernetes_secret" "reindexer_elasticsearch_credentials" {
  for_each    = var.reindexer
  metadata {
    name      = "${each.key}-reindexer-elastic-credentials"
    namespace = try(each.value.namespace, local.namespace)
  }
  data        = data.kubernetes_secret.reindexer_elasticsearch_credentials[each.key].data
}

data "kubernetes_secret" "reindexer_elasticsearch_certs" {
  for_each    = var.reindexer
  metadata {
    name      = "elastic-https-certs"
    namespace = try(each.value.elasticsearch_namespace, local.elasticsearch_namespace)
  }
}

resource "kubernetes_secret" "reindexer_elasticsearch_certs" {
  for_each    = var.reindexer
  metadata {
    name      = "${each.key}-reindexer-elastic-https-certs"
    namespace = try(each.value.namespace, local.namespace)
  }
  data        = data.kubernetes_secret.reindexer_elasticsearch_certs[each.key].data
}

data "vault_generic_secret" "reindexer_slack" {
  path        = "secret/slack/elastic_reindexer"
}

resource "kubernetes_secret" "reindexer_slack" {
  for_each    = var.reindexer
  metadata {
    name      = "${each.key}-reindexer-slack"
    namespace = try(each.value.namespace, local.namespace)
  }

  data = {
    token     = data.vault_generic_secret.reindexer_slack.data.token,
    channel     = data.vault_generic_secret.reindexer_slack.data.channel
  }
}

data "vault_generic_secret" "reindexer_rf_es_creds" {
  path        = "secret/misc/elastic/fraud"
}

resource "kubernetes_secret" "reindexer_rf_es_creds" {
  for_each    = var.reindexer
  metadata {
    name      = "${each.key}-reindexer-rf-es-creds"
    namespace = try(each.value.namespace, local.namespace)
  }

  data = {
    username     = data.vault_generic_secret.reindexer_rf_es_creds.data.username,
    password     = data.vault_generic_secret.reindexer_rf_es_creds.data.password,
    host         = data.vault_generic_secret.reindexer_rf_es_creds.data.host
  }
}

resource "kubernetes_deployment_v1" "elasticsearch_reindexer" {
  for_each    = var.reindexer
  metadata {
    name      = "${each.key}-reindexer"
    namespace = try(each.value.namespace, local.namespace)
    labels = {
      app     = "${each.key}-reindexer"
    }
  }

  spec {
    replicas = 0

    selector {
      match_labels = {
        app = "${each.key}-reindexer"
      }
    }

    template {
      metadata {
        labels = {
          app     = "${each.key}-reindexer"
        }
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }

      spec {
        container {
          image = "harbor.regemini.io/op/reindexer:${var.reindexer_version}"
          name  = "reindexer"
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
                name = kubernetes_secret.reindexer_elasticsearch_credentials[each.key].metadata.0.name
              }
            }
          }
          env {
            name = "SLACK_TOKEN"
            value_from {
              secret_key_ref {
                key  = "token"
                name = kubernetes_secret.reindexer_slack[each.key].metadata.0.name
              }
            }
          }
          env {
            name  = "SLACK_CHANNEL"
            value_from {
              secret_key_ref {
                key  = "channel"
                name = kubernetes_secret.reindexer_slack[each.key].metadata.0.name
              }
            }
          }
          env {
            name  = "RF_ES_HOST"
            value_from {
              secret_key_ref {
                key  = "host"
                name = kubernetes_secret.reindexer_rf_es_creds[each.key].metadata.0.name
              }
            }
          }
          env {
            name  = "RF_ES_USER"
            value_from {
              secret_key_ref {
                key  = "username"
                name = kubernetes_secret.reindexer_rf_es_creds[each.key].metadata.0.name
              }
            }
          }
          env {
            name  = "RF_ES_PASS"
            value_from {
              secret_key_ref {
                key  = "password"
                name = kubernetes_secret.reindexer_rf_es_creds[each.key].metadata.0.name
              }
            }
          }
          volume_mount {
            mount_path = "/opt/reindex/certs"
            name       = "elasticsearch-certs"
          }
          volume_mount {
            mount_path = "/opt/reindex/rf_certs"
            name       = "rf-es-ca"
          }
        }
        image_pull_secrets {
          name = "harbor"
        }
        node_selector = {
          workloadsType = "recorded-future"
        }
        toleration {
          key = "workloadsType"
          operator = "Equal"
          value = "recorded-future"
          effect = "NoSchedule"
        }
        volume {
          name = "elasticsearch-certs"
          projected {
            sources {
              secret {
                name = kubernetes_secret.reindexer_elasticsearch_certs[each.key].metadata.0.name
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
        volume {
          name = "rf-es-ca"
          projected {
            sources {
              secret {
                name = kubernetes_secret.reindexer_rf_es_creds[each.key].metadata.0.name
                items {
                  key = "ca.crt"
                  path = "ca.crt"
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
