# resource "kubernetes_deployment" "etl_observer" {
#   metadata {
#     name      = "etl-observer"
#     namespace = "etl"
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = "etl-observer"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app = "etl-observer"
#         }
#         annotations = {
#           "co.elastic.logs/enabled"       = "false"
#           "vault.hashicorp.com/auth-path" = "auth/k8s-${var.Cluster}-${var.Color}"
#           "vault.hashicorp.com/role"      = "etl"
#           "vaultAddr"                     = "http://vault-active.vault:8200"
#         }
#       }

#       spec {
#         container {
#           name  = "etl-observer"
#           image = "harbor.regemini.io/op/etl-observer:${local.observerTag}"

#           port {
#             container_port = 5000
#             name           = "endpoint"
#             protocol       = "TCP"
#           }
#           dynamic "env" {
#             for_each = local.minio_endpoints
#             content {
#               name  = env.value["var_name"]
#               value = env.value["path"]
#             }

#           }
#           # env {
#           #   name = "MINIO_ENDPOINTS"
#           #   value_from {
#           #     config_map_key_ref {
#           #       name = kubernetes_config_map.minio_endpoints.metadata[0].name
#           #       key  = "endpoints"
#           #     }
#           #   }
#           # }

#           # env {
#           #   name = "MINIO_ACCESS_KEY"
#           #   value_from {
#           #     secret_key_ref {
#           #       name = "minio-credentials"
#           #       key  = "accesskey"
#           #     }
#           #   }
#           # }

#           # env {
#           #   name = "MINIO_SECRET_KEY"
#           #   value_from {
#           #     secret_key_ref {
#           #       name = "minio-credentials"
#           #       key  = "secretkey"
#           #     }
#           #   }
#           # }
#           env {
#             name = "VAULT_ROLE"
#             value_from {
#               field_ref {
#                 api_version = "v1"
#                 field_path  = "metadata.annotations['vault.hashicorp.com/role']"
#               }
#             }
#           }
#           env {
#             name = "VAULT_AUTH_PATH"
#             value_from {
#               field_ref {
#                 api_version = "v1"
#                 field_path  = "metadata.annotations['vault.hashicorp.com/auth-path']"
#               }
#             }
#           }
#           env {
#             name = "VAULT_ADDR"
#             value_from {
#               field_ref {
#                 api_version = "v1"
#                 field_path  = "metadata.annotations['vaultAddr']"
#               }
#             }
#           }
#           env {
#             name  = "ELASTICSEARCH_SECRET_PATH"
#             value = local.elasticSecretsPathNew
#           }
#           env {
#             name  = "ELASTIC_APM_SERVER_URL"
#             value = "http://apm-mon-apm-http.monitoring:8200"
#           }
#           env {
#             name = "ELASTIC_APM_SECRET_TOKEN"
#             value_from {
#               secret_key_ref {
#                 name = "apm-token"
#                 key  = "secret-token"
#               }
#             }
#           }
#         }

#         image_pull_secrets {
#           name = "harbor"
#         }
#       }
#     }
#   }
# }






# resource "kubernetes_service" "etl_observer" {
#   metadata {
#     name      = "etl-observer"
#     namespace = "etl"

#     labels = {
#       app = "etl-observer"
#     }
#   }

#   spec {
#     selector = {
#       app = "etl-observer"
#     }

#     port {
#       protocol    = "TCP"
#       port        = 5000
#       target_port = 5000
#     }

#     type = "ClusterIP"
#   }
# }
