
locals {
  accessKey               = jsondecode(data.vault_generic_secret.minio_creds.data["backup"]).accessKey
  secretKey               = jsondecode(data.vault_generic_secret.minio_creds.data["backup"]).secretKey
  minioIntegrationCommand = <<EOT

  curl -X DELETE "https://elastic:$ES_PASSWORD@${var.ElasticName}-es-http:9200/_snapshot/minio"
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
EOT
}



resource "kubernetes_job" "minio_snapshot_storage" {
  metadata {
    name      = "${var.ElasticName}-minio-snapshot-storage-reenable-${lower(random_id.rand.hex)}"
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
