# locals {
#   date_now                = formatdate("YYYYMMDD", timestamp())
#   EsService               = "mon-es-http.monitoring.svc:9200"
#   BackupBucketName        = "xbackup"
#   BackupBucketBasePath    = "es-backup/monitoring"
#   EsCreds                 = "mon-es-elastic-user"
#   minioIntegrationCommand = <<EOT
#   set -e
#   curl -k -X DELETE "https://elastic:$ES_PASSWORD@${local.EsService}/_snapshot/minio"
#   curl -X PUT "https://elastic:$ES_PASSWORD@${local.EsService}/_snapshot/minio" -H 'Content-Type: application/json' -k -d '
# {
#      "type": "s3",
#       "settings": {
#          "bucket": "minio-${local.BackupBucketName}-${var.Settings.gcpProject}",
#          "endpoint": "${var.Settings.clusters[var.Cluster].MinioAddress}",
#          "protocol": "http",
#          "path_style_access": true,
#          "base_path": "${local.BackupBucketBasePath}"
#       }
#   }
#   '
#   curl -k -X GET "https://elastic:$ES_PASSWORD@${local.EsService}/_cat/snapshots/minio"
# EOT
# }

# resource "random_id" "rand" {
#   byte_length = 8
#   prefix      = "curator-"
# }

# resource "kubernetes_job" "minio_snapshot_storage" {
#   metadata {
#     name      = "snapstor-reenable-${lower(random_id.rand.hex)}"
#     namespace = "monitoring"
#   }
#   spec {
#     template {
#       metadata {

#         annotations = {
#           "sidecar.istio.io/inject" = "false"
#         }
#       }
#       spec {
#         container {
#           name    = "curl"
#           image   = "curlimages/curl"
#           command = ["sh", "-c", local.minioIntegrationCommand]
#           env {
#             name = "ES_PASSWORD"
#             value_from {
#               secret_key_ref {
#                 name = local.EsCreds
#                 key  = "elastic"
#               }
#             }
#           }
#           resources {
#             requests = {
#               cpu    = "10m"
#               memory = "10M"
#             }
#           }
#         }
#         restart_policy = "Never"
#       }
#     }
#     backoff_limit = 1
#   }
#   wait_for_completion = true

#   timeouts {
#     create = "5m"
#     update = "5m"
#   }
# }

# data "kubernetes_secret" "password" {
#   metadata {
#     name      = "mon-es-elastic-user"
#     namespace = "monitoring"
#   }
# }

# data "kubernetes_secret" "certs" {
#   metadata {
#     name      = "mon-es-http-certs-internal"
#     namespace = "monitoring"
#   }
# }


# resource "null_resource" "elastic_restore" {
#   triggers = {
#     restore_check = md5(file("../../../references/elastic-restore/restore.py"))
#   }
#   provisioner "local-exec" {
#     command = <<COMMAND
#     python3 "../../../references/elastic-restore/restore.py"
# COMMAND
#     environment = {
#       ELASTICSEARCH_USERNAME = "elastic"
#       ELASTICSEARCH_PASSWORD = data.kubernetes_secret.password.data.elastic
#       ELASTICSEARCH_URL      = local.EsService
#       CA_CERT                = data.kubernetes_secret.certs.data["ca.crt"]
#       WAIT_FC                = "True"
#       SNAPSHOTS              = "monitoring-dr-system-${local.date_now},monitoring-lfb-system-${local.date_now}"
#     }
#   }
#   depends_on = [module.backup-lfb]
# }

