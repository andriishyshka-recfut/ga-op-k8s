
locals {
  minio-ns = "minio"
}
resource "kubernetes_namespace" "minio" {
  metadata {
    name = local.minio-ns
    # labels = {
    #   istio-injection = "enabled"
    # }
  }
}
# resource "kubernetes_limit_range" "minio" {
#   metadata {
#     name      = "minio"
#     namespace = local.minio-ns
#
#   }
#   spec {
#     limit {
#       type = "Pod"
#       default = {
#         cpu    = "500m"
#         memory = "1024Mi"
#       }
#     }
#
#     limit {
#       type = "Container"
#       default_request = {
#         cpu    = "10m"
#         memory = "24Mi"
#       }
#     }
#   }
# }

data "vault_generic_secret" "minio-credentials" {
  path = "secret/minio-credentials"
}

resource "kubernetes_secret" "minio-credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = local.minio-ns
  }

  data = {
    "accesskey" = data.vault_generic_secret.minio-credentials.data.accessKey
    "secretkey" = data.vault_generic_secret.minio-credentials.data.secretKey
  }
  depends_on = [kubernetes_namespace.minio]

}



resource "helm_release" "minio" {
  name       = "minio"
  chart      = "minio"
  repository = "https://helm.min.io/"
  #version           = "0.1.0"
  namespace         = local.minio-ns
  dependency_update = "true"

  values = [
    templatefile("${path.root}/minio_values.tmpl",
      {
        CLIENT_ID          = data.vault_generic_secret.oidc_secrets.data.oidc_client_id
        OIDC_DISCOVERY_URL = data.vault_generic_secret.oidc_secrets.data.oidc_discovery_url
      }
    )
  ]
  depends_on = [
    kubernetes_namespace.minio,
    kubernetes_secret.minio-credentials
  ]
}


resource "kubernetes_config_map" "policy" {
  metadata {
    name      = "policy"
    namespace = local.minio-ns
  }
  data = {
    policy_json = file("minio-policy.json")
  }
}

resource "kubernetes_job" "add-policy" {
  metadata {
    name      = "add-policy"
    namespace = local.minio-ns
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "mc"
          image   = "minio/mc"
          command = ["mc", "admin", "policy", "add", "maid", "geminiadvisory.io", "/tmp/policy_json"]
          env {
            name = "accesskey"
            value_from {
              secret_key_ref {
                name = "minio-credentials"
                key  = "accesskey"
              }
            }
          }
          env {
            name = "secretkey"
            value_from {
              secret_key_ref {
                name = "minio-credentials"
                key  = "secretkey"
              }
            }
          }
          env {
            name  = "MC_HOST_maid"
            value = "http://$(accesskey):$(secretkey)@minio:9000"
          }
          volume_mount {
            mount_path = "/tmp/"
            name       = "policy"
          }

        }
        volume {
          name = "policy"
          config_map {
            #key  = "policy_json"
            name = "policy"
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  depends_on = [
    helm_release.minio,
    kubernetes_config_map.policy
  ]
}
