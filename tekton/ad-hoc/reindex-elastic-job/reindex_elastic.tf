data "vault_generic_secret" "elastic_creds" {
  path = local.elasticSecretsPath
}


data "vault_generic_secret" "slack_creds" {
  path = local.slackTokenPath
}


data "vault_generic_secret" "elastic_ca" {
  path = "${local.elasticCertsPath}/elasticCa"
}

data "vault_generic_secret" "elastic_crt" {
  path = "${local.elasticCertsPath}/elasticCrt"
}

data "vault_generic_secret" "elastic_key" {
  path = "${local.elasticCertsPath}/elasticKey"
}


resource "kubernetes_secret" "elastic_certs" {
  metadata {
    name      = "elastic-certs"
    namespace = "core"
  }
  data = {
    ca  = data.vault_generic_secret.elastic_ca.data.ELASTICSEARCH_CA_CRT
    tls = data.vault_generic_secret.elastic_crt.data.ELASTICSEARCH_CLIENT_CRT
    key = data.vault_generic_secret.elastic_key.data.ELASTICSEARCH_CLIENT_KEY
  }

}

resource "kubernetes_job" "reindex_elastic" {
  metadata {
    generate_name = "reindex-elastic-${local.run_prefix}"
    namespace     = "core"
  }
  spec {
    template {
      metadata {
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        image_pull_secrets {
          name = "harbor"
        }

        container {
          image_pull_policy = "Always"
          name              = "reindex-elastic"
          image             = "harbor.regemini.io/op/reindexer:${local.imageTag}"
          #   command = ["./venv/bin/python3", "-W", "ignore", "universal_reindexer.py", "-t", local.template, "-v", local.version, "-w", "./", "-d"]
          command = ["tail", "-f", "/dev/null"]
          env {
            name  = "ES_PASS"
            value = jsondecode(data.vault_generic_secret.elastic_creds.data["CREDENTIALS"]).password
          }
          env {
            name  = "ES_HOST"
            value = jsondecode(data.vault_generic_secret.elastic_creds.data["HOSTS"])[0]
          }
          env {
            name  = "ES_PORT"
            value = 443
          }
          env {
            name  = "SLACK_CHANNEL"
            value = local.slackChannel
          }
          env {
            name  = "SLACK_TOKEN"
            value = data.vault_generic_secret.slack_creds.data.token
          }
          env {
            name  = "BLOCK_KAFKA_TOPICS"
            value = local.block_kafka_topics
          }
          volume_mount {
            mount_path = local.workDir
            name       = "workdir"
          }

          volume_mount {
            name       = "es-certs"
            mount_path = "${local.workDir}/certs"
          }
        }

        volume {
          name = "workdir"
          persistent_volume_claim {
            claim_name = "reindex-elastic-${local.run_prefix}"
          }
        }

        volume {
          name = "es-certs"
          secret {
            secret_name = kubernetes_secret.elastic_certs.metadata[0].name
            items {
              key  = "ca"
              path = "http_ca.crt"
            }
            items {
              key  = "tls"
              path = "client.crt"
            }

            items {
              key  = "key"
              path = "client.key"
            }
          }
        }

        restart_policy = "Never"
      }
    }
    backoff_limit = 0
  }
  wait_for_completion = false
  depends_on          = [kubernetes_secret.elastic_certs, kubernetes_persistent_volume_claim.workdir_pvc]
}



resource "kubernetes_persistent_volume_claim" "workdir_pvc" {
  metadata {
    name      = "reindex-elastic-${local.run_prefix}"
    namespace = "core"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
    storage_class_name = "standard"
  }
}

