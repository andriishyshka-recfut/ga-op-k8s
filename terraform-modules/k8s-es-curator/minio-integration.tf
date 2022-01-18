
locals {

  minioIntegrationCommand = <<EOT
  set -e
  curl -k -X DELETE "https://elastic:$ES_PASSWORD@${var.ElasticName}-es-http:9200/_snapshot/minio"
  curl -X PUT "https://elastic:$ES_PASSWORD@${var.ElasticName}-es-http:9200/_snapshot/minio" -H 'Content-Type: application/json' -k -d '
{
     "type": "s3",
      "settings": {
         "bucket": "minio-xbackup-${local.currentProject}",
         "endpoint": "minio.minio:9000",
         "protocol": "http",
         "path_style_access": true
      }
  }
  '
  curl -k -X GET "https://elastic:$ES_PASSWORD@${var.ElasticName}-es-http:9200/_cat/snapshots/minio"
EOT
}



resource "kubernetes_job" "minio_snapshot_storage" {
  metadata {
    name      = "snapstor-reenable-${lower(random_id.rand.hex)}"
    namespace = var.Namespace
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
          command = ["sh", "-c", local.minioIntegrationCommand]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "${var.ElasticName}-es-elastic-user"
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
    backoff_limit = 1
  }
  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}
