
locals {
  gcsIntegrationRepo = <<EOT
  curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_snapshot/gcs" -H 'Content-Type: application/json' -k -d '
{
  "type": "gcs",
  "settings": {
    "bucket": "es-backup-asdsafawdgasd",
    "client": "default"
    }
  }
  '
EOT
  gcsFullBackup      = <<EOT
  until curl --head localhost:15000 ; do echo Waiting for Sidecar; sleep 3 ; done ; echo Sidecar available;curl -s -i -k -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_snapshot/gcs/%3Ces_full_%7Bnow%2Fd%7D%3E?wait_for_completion=true" | tee /dev/stderr | grep "200 OK" && curl -XPOST "http://localhost:15000/quitquitquit"
EOT
}

data "vault_generic_secret" "elastic_sa" {
  path = "secret/sa/elastic"
}

resource "kubernetes_secret" "gcs_es_credentional" {
  count = local.gcsSetup
  metadata {
    name = "gcs-es-credentional"
    //after test change to variable
    namespace = local.esValues.namespace
  }
  data = {
    "gcs.client.default.credentials_file" = base64decode(data.vault_generic_secret.elastic_sa.data.gcs_key)
  }
  type = "general"
}
resource "kubernetes_job" "gcs_es_backup_storage" {
  count = local.gcsSetup
  metadata {
    name      = "${local.esValues.esName}-gcs-snapshot-storage"
    namespace = local.esValues.namespace
  }
  spec {
    template {
      metadata {
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        container {
          name    = "curl"
          image   = "curlimages/curl"
          command = ["sh", "-c", local.gcsIntegrationRepo]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "${local.esValues.esName}-es-elastic-user"
                key  = "elastic"
              }
            }
          }
          resources {
            requests = {
              cpu    = "10m"
              memory = "10M"
            }
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  depends_on = [
    null_resource.ansible_validate_resources
  ]
  timeouts {
    create = "5m"
    update = "5m"
  }
}
resource "kubernetes_cron_job" "gcs_es_fullbackup" {
  count = local.gcsSetup
  metadata {
    name      = "${local.esValues.esName}-gcs-es-cronjob"
    namespace = local.esValues.namespace
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 10
    successful_jobs_history_limit = 10
    schedule                      = "0 5 * * *"
    job_template {
      metadata {}
      spec {
        backoff_limit = 4
        template {
          metadata {}
          spec {
            restart_policy = "Never"
            container {
              name    = "curl"
              image   = "curlimages/curl"
              command = ["sh", "-c", local.gcsFullBackup]
              env {
                name = "ES_PASSWORD"
                value_from {
                  secret_key_ref {
                    name = "${local.esValues.esName}-es-elastic-user"
                    key  = "elastic"
                  }
                }
              }
              resources {
                requests = {
                  cpu    = "10m"
                  memory = "10M"
                }
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_job.gcs_es_backup_storage
  ]
}
