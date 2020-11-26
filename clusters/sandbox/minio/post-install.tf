
resource "kubernetes_config_map" "policy" {
  metadata {
    name      = "policy"
    namespace = local.minio-ns
  }
  data = {
    "policy.json"             = file("minio-policy.json")
    "policy_maid.json"        = file("minio-policy-maid.json")
    "policy_magescanner.json" = file("minio-policy-magescanner.json")
  }
}

locals {
  addPolicyCommand = <<EOF
  mc admin policy add minio geminiadvisory.io /tmp/policy.json
  mc admin policy add minio maid /tmp/policy_maid.json
  mc admin policy add minio magescanner /tmp/policy_magescanner.json
  mc admin user add minio ${data.vault_generic_secret.minio-credentials.data.maidAccessKey} ${data.vault_generic_secret.minio-credentials.data.maidSecretKey}
  mc admin policy set minio maid user=${data.vault_generic_secret.minio-credentials.data.maidAccessKey}
  mc admin user add minio ${data.vault_generic_secret.minio-credentials.data.magescannerAccessKey} ${data.vault_generic_secret.minio-credentials.data.magescannerSecretKey}
  mc admin policy set minio magescanner user=${data.vault_generic_secret.minio-credentials.data.magescannerAccessKey}
EOF
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
          command = ["sh", "-c", local.addPolicyCommand]
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
            name  = "MC_HOST_minio"
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
