
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
  mc --insecure admin policy create minio ${user} /tmp/${replace(user, "@", "-")}_policy.json
  mc --insecure admin user add minio ${jsondecode(data.vault_generic_secret.users_credentials_from_vault.data[user]).accessKey} ${jsondecode(data.vault_generic_secret.users_credentials_from_vault.data[user]).secretKey}
  mc --insecure admin policy attach minio ${user} --user=${jsondecode(data.vault_generic_secret.users_credentials_from_vault.data[user]).accessKey}
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

resource "kubernetes_secret" "minio_credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = local.minioNs
  }

  data = {
    "accesskey" = data.vault_generic_secret.root_credentials_from_vault.data.accessKey
    "secretkey" = data.vault_generic_secret.root_credentials_from_vault.data.secretKey
  }

}


# resource "null_resource" "ansible_wait_for_minio_tenant" {

#   triggers = {
#     playbook_contents = md5(file("${path.module}/../../ansible/k8s-wait-for.yml"))
#   }
#   provisioner "local-exec" {
#     command = <<COMMAND
#     cd ${path.module}/../../ansible &&\
#     ansible-playbook k8s-wait-for.yml

# COMMAND
#     environment = merge(local.ansibleEnvs, {
#       name           = "minio-tenant"
#       kind           = "tenant"
#       namespace      = local.minioNs
#       apiVersion     = "minio.min.io/v2"
#       statusPath     = "currentState"
#       requiredStatus = "Initialized"
#     })
#   }
#   depends_on = [
#     helm_release.minio_tenant
#   ]
# }

resource "time_sleep" "wait_for_tenant" {
  depends_on = [helm_release.minio_tenant]

  create_duration = "40s"
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
          image   = "minio/mc:${local.mcImageTag}"
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
            value = "https://$(accesskey):$(secretkey)@minio:443"
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
    backoff_limit = 0
  }
  wait_for_completion = true
  timeouts {
    create = "10m"
    update = "3m"
  }
  depends_on = [
    kubernetes_secret.minio_users_secret,
    kubernetes_secret.minio_credentials,
    kubernetes_config_map.policy,
    time_sleep.wait_for_tenant
  ]
}
