locals {
  minioSecretPath         = try(local.globalSettings.minio.vaultPath, "secret/minio/users")
  legacyMinioCreds        = try(jsondecode(data.vault_generic_secret.minio_creds.data["elastic-backup"]), {})
  accessKey               = try(data.vault_generic_secret.minio_creds.data["ACCESS_KEY_ID"], local.legacyMinioCreds.accessKey)
  secretKey               = try(data.vault_generic_secret.minio_creds.data["SECRET_ACCESS_KEY"], local.legacyMinioCreds.secretKey)
  backupBucketName        = try(local.globalSettings.minio.bucket, "minio-${var.BackupBucketName}-${local.currentProject}")
  minioProtocol           = try(local.globalSettings.minio.protocol, "http")
  minioEndpoint           = try(local.globalSettings.minio.endpoint, var.MinioAddress)
  minioCa                 = try(data.vault_generic_secret.minio_creds.data["CA_CRT"], null)
  minioIntegrationCommand = <<EOT

  curl -X PUT "https://elastic:$ES_PASSWORD@${local.httpServive}:9200/_snapshot/minio" -H 'Content-Type: application/json' -k -d '
{
     "type": "s3",
      "settings": {
         "bucket": "${local.backupBucketName}",
         "endpoint": "${local.minioEndpoint}",
         "protocol": "${local.minioProtocol}",
         "path_style_access": true,
         "base_path": "${var.BackupBucketBasePath}"
      }
  }
  '
EOT
}

data "vault_generic_secret" "minio_creds" {
  path = local.minioSecretPath
}

resource "kubernetes_secret" "minio_ca" {
  count = try(local.globalSettings.minio.vaultPath, null) != null ? 1 : 0

  metadata {
    name      = "minio-ca-certs"
    namespace = local.globalSettings.namespace
  }

  data = {
    "ca.crt" = local.minioCa
  }
}

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
