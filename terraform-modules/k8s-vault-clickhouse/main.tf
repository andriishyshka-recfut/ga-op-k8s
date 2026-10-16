resource "terraform_data" "configuration_validation" {
  lifecycle {
    precondition {
      condition     = local.persistent_keeper.count == local.keeper_replicas
      error_message = "ClickHouse Keeper permanent disk count must equal keeper_replicas."
    }

    precondition {
      condition = length(local.persistent_clickhouse) == local.shards && alltrue([
        for shard in range(local.shards) : try(local.persistent_clickhouse["shard-${shard}"].count == local.replicas, false)
      ])
      error_message = "ClickHouse permanent disks must define shard-0 through shard-N, each with count equal to replicas."
    }

    precondition {
      condition     = local.keeper_replicas > 0 && local.keeper_replicas % 2 == 1
      error_message = "ClickHouse Keeper replicas must be a positive odd number."
    }

    precondition {
      condition = alltrue([
        local.clickhouse_storage_size != null,
        local.keeper_storage_size != null,
        local.workloads_type != null,
      ])
      error_message = "Enabled ClickHouse configuration must define both storage sizes and workloadsType."
    }
  }
}

ephemeral "vault_kv_secret_v2" "authentication" {
  mount = local.vault_mount
  name  = local.vault_auth_path
}

resource "kubernetes_secret_v1" "authentication" {
  metadata {
    name      = local.password_secret_name
    namespace = local.namespace
  }

  data_wo = {
    username = tostring(ephemeral.vault_kv_secret_v2.authentication.data["username"])
    password = tostring(ephemeral.vault_kv_secret_v2.authentication.data["password"])
  }
  data_wo_revision = 1

  type = "Opaque"

  depends_on = [terraform_data.configuration_validation]
}

resource "helm_release" "operator" {
  name            = "clickhouse-operator"
  namespace       = local.operator_namespace
  repository      = "oci://ghcr.io/clickhouse"
  chart           = "clickhouse-operator-helm"
  version         = local.chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    controller = {
      watchNamespaces = [local.namespace]
    }
    crd = {
      enabled = true
      keep    = true
    }
  })]

  depends_on = [terraform_data.configuration_validation]
}

resource "helm_release" "cluster" {
  name            = local.cluster_name
  namespace       = local.namespace
  repository      = "oci://ghcr.io/clickhouse"
  chart           = "clickhouse-cluster-helm"
  version         = local.chart_version
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    clickhouse = {
      enabled = true
      meta = {
        name = local.cluster_name
      }
      spec = {
        shards   = local.shards
        replicas = local.replicas
        externalSecret = {
          name   = local.cluster_secret_name
          policy = "Observe"
        }
        containerTemplate = merge({
          image = {
            tag = local.image_tag
          }
          resources = local.clickhouse_resources
          }, local.backup_enabled ? {
          env = [
            {
              name = "AWS_ACCESS_KEY_ID"
              valueFrom = {
                secretKeyRef = {
                  name = local.backup_secret_name
                  key  = "access_key"
                }
              }
            },
            {
              name = "AWS_SECRET_ACCESS_KEY"
              valueFrom = {
                secretKeyRef = {
                  name = local.backup_secret_name
                  key  = "secret_key"
                }
              }
            },
          ]
        } : {})
        dataVolumeClaimSpec = {
          accessModes      = ["ReadWriteOnce"]
          storageClassName = ""
          selector = {
            matchLabels = {
              target = local.pv_selector_label
            }
          }
          resources = {
            requests = {
              storage = local.clickhouse_storage_size
            }
          }
        }
        podTemplate = local.pod_template
        keeperClusterRef = {
          name = local.keeper_name
        }
        settings = merge({
          tls = {
            enabled  = true
            required = true
            serverCertSecret = {
              name = local.tls_secret_name
            }
            caBundle = {
              name = local.tls_secret_name
              key  = "ca.crt"
            }
          }
          defaultUserPassword = {
            secret = {
              name = local.password_secret_name
              key  = "password"
            }
            passwordType = "password"
          }
          }, local.backup_enabled ? {
          extraConfig = {
            storage_configuration = {
              disks = {
                (local.backup_disk_name) = {
                  type                        = "s3_plain"
                  endpoint                    = local.backup_endpoint
                  use_environment_credentials = true
                }
              }
            }
            backups = {
              allowed_disk = local.backup_disk_name
            }
          }
        } : {})
      }
    }
    keeper = {
      enabled = true
      meta = {
        name = local.keeper_name
      }
      spec = {
        replicas = local.keeper_replicas
        settings = {
          tls = {
            enabled  = true
            required = true
            serverCertSecret = {
              name = local.keeper_tls_secret_name
            }
            caBundle = {
              name = local.keeper_tls_secret_name
              key  = "ca.crt"
            }
          }
        }
        containerTemplate = {
          image = {
            tag = local.image_tag
          }
          resources = local.keeper_resources
        }
        dataVolumeClaimSpec = {
          accessModes      = ["ReadWriteOnce"]
          storageClassName = ""
          selector = {
            matchLabels = {
              target = local.keeper_selector_label
            }
          }
          resources = {
            requests = {
              storage = local.keeper_storage_size
            }
          }
        }
        podTemplate = local.pod_template
      }
    }
  })]

  depends_on = [
    helm_release.operator,
    kubernetes_secret_v1.authentication,
    kubernetes_secret_v1.cluster,
    kubernetes_secret_v1.backup_minio,
    kubernetes_manifest.certificate,
    kubernetes_persistent_volume.clickhouse_pv,
    kubernetes_persistent_volume_claim.clickhouse_pvc,
    kubernetes_persistent_volume.keeper_pv,
    kubernetes_persistent_volume_claim.keeper_pvc,
  ]
}
