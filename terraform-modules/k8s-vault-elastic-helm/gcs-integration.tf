
locals {
  gcsIntegrationRepo = <<EOT
  curl -X PUT "https://elastic:$ES_PASSWORD@${local.httpServive}:9200/_snapshot/gcs" -H 'Content-Type: application/json' -k -d '
{
  "type": "gcs",
  "settings": {
    "bucket": "es-backup-asdsafawdgasd",
    "client": "default"
    }
  }
  '
EOT

}

data "vault_generic_secret" "elastic_sa" {
  path = lookup(local.globalSettings, "gcsVaultPath", "secret/sa/elastic")
}

resource "kubernetes_secret" "gcs_es_credentional" {
  count = contains(local.globalSettings.plugins, "repository-gcs") ? 1 : 0
  metadata {
    name      = "gcs-credentials"
    namespace = local.globalSettings.namespace
  }
  data = {
    "gcs.client.default.credentials_file" = base64decode(data.vault_generic_secret.elastic_sa.data.gcs_key)
  }
  type = "general"
}
resource "kubernetes_job" "gcs_es_backup_storage" {
  count = contains(local.globalSettings.plugins, "repository-gcs") ? 1 : 0
  metadata {
    name      = "${local.globalSettings.clusterName}-gcs-snapshot-storage"
    namespace = local.globalSettings.namespace
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
                name = "elastic-credentials"
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
    helm_release.elastic
  ]
  timeouts {
    create = "5m"
    update = "5m"
  }
}
