
data "vault_generic_secret" "users_credentials_from_vault" {
  path = local.vaultUsersCredentialsPath
}

locals {
  policiesConfigMapData = tomap({ for user in keys(data.vault_generic_secret.users_credentials_from_vault.data) :
  "${replace(user, "@", "-")}_policy.json" => jsonencode(jsondecode(data.vault_generic_secret.users_credentials_from_vault.data[user]).policy) })

  addPolicyCommand = <<EOF
  set +x
  set -e
  %{for user in keys(data.vault_generic_secret.users_credentials_from_vault.data)~}
  mc admin policy add minio ${user} /tmp/${replace(user, "@", "-")}_policy.json
  mc admin user add minio ${jsondecode(data.vault_generic_secret.users_credentials_from_vault.data[user]).accessKey} ${jsondecode(data.vault_generic_secret.users_credentials_from_vault.data[user]).secretKey}
  mc admin policy set minio  ${user} user=${jsondecode(data.vault_generic_secret.users_credentials_from_vault.data[user]).accessKey}
  %{endfor~}

EOF

}

resource "kubernetes_config_map" "policy" {
  metadata {
    name      = "policy"
    namespace = local.minioNs
  }
  data = local.policiesConfigMapData
}

resource "kubernetes_secret" "minio_users_secret" {
  metadata {
    name      = "minio-users"
    namespace = local.minioNs
  }

  data = {
    "users.sh" = local.addPolicyCommand
  }

}

resource "kubernetes_job" "configure_users_access" {
  metadata {
    name      = "minio-users-access"
    namespace = local.minioNs
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
          name    = "mc"
          image   = "harbor.regemini.io/mirror/mc:${local.mcImageTag}"
          command = ["bash", "/etc/secret/users.sh"]
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
          env {
            name  = "USERS_MD5"
            value = md5(local.addPolicyCommand)
          }
          env {
            name  = "POLICY_MD5"
            value = md5(jsonencode(local.policiesConfigMapData))
          }
          volume_mount {
            mount_path = "/tmp/"
            name       = "policy"
          }
          volume_mount {
            mount_path = "/etc/secret/"
            name       = "users"
          }

        }
        volume {
          name = "policy"
          config_map {
            #key  = "policy_json"
            name = "policy"
          }
        }
        volume {
          name = "users"
          secret {
            #key  = "policy_json"
            secret_name = "minio-users"
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 1
  }
  wait_for_completion = true
  timeouts {
    create = "15m"
    update = "15m"
  }
  depends_on = [
    helm_release.minio,
    kubernetes_config_map.policy
  ]
}
