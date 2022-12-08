data "vault_generic_secret" "minio_creds" {
  path = "secret/minio/users"
}
locals {
  accessKey               = jsondecode(data.vault_generic_secret.minio_creds.data["elastic-backup"]).accessKey
  secretKey               = jsondecode(data.vault_generic_secret.minio_creds.data["elastic-backup"]).secretKey
  minioIntegrationCommand = <<EOT

  curl -X PUT "https://elastic:$ES_PASSWORD@${local.httpServive}:9200/_snapshot/minio" -H 'Content-Type: application/json' -k -d '
{
     "type": "s3",
      "settings": {
         "bucket": "minio-${var.BackupBucketName}-${local.currentProject}",
         "endpoint": "${var.MinioAddress}",
         "protocol": "http",
         "path_style_access": true,
         "base_path": "${var.BackupBucketBasePath}"
      }
  }
  '
EOT
}


# data "vault_generic_secret" "minio_creds" {
#   path = "secret/minio/users"
# }
# locals {
#   accessKey               = jsondecode(data.vault_generic_secret.minio_creds.data["elastic-backup"]).accessKey
#   secretKey               = jsondecode(data.vault_generic_secret.minio_creds.data["elastic-backup"]).secretKey
#   minioIntegrationCommand = <<EOT

#   curl -X PUT "https://elastic:$ES_PASSWORD@elasticsearch-coor:9200/_snapshot/minio" -H 'Content-Type: application/json' -k -d '
# {
#      "type": "s3",
#       "settings": {
#          "bucket": "minio-es7-ardent-rarity-239115",
#          "endpoint": "minio.minio:9000",
#          "protocol": "http",
#          "path_style_access": true,
#          "base_path": "test"
#       }
#   }
#   '
# EOT
# }



resource "kubernetes_secret" "minio_credentials" {
  count = contains(local.globalSettings.plugins, "repository-s3") ? 1 : 0
  metadata {
    name      = "minio-credentials"
    namespace = local.globalSettings.namespace
  }
  data = {
    "s3.client.default.access_key" = local.accessKey
    "s3.client.default.secret_key" = local.secretKey
  }
}

resource "kubernetes_job" "minio_snapshot_storage" {
  count = contains(local.globalSettings.plugins, "repository-s3") ? 1 : 0
  metadata {
    name      = "${local.globalSettings.clusterName}-minio-snapshot-storage"
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
          command = ["sh", "-c", local.minioIntegrationCommand]
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
  timeouts {
    create = "5m"
    update = "5m"
  }
  depends_on = [
    helm_release.elastic
  ]
}
