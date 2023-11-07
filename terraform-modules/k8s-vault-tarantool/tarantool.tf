data "vault_generic_secret" "minio_credentials" {
  path = "secret/minio/users"
}

data "vault_generic_secret" "tarantool_credentials" {
  path = "secret/vortex/tarantool"
}


data "google_compute_disk" "tarantool_data_pv" {
  count   = local.pv_disk_count
  name    = "${local.pv_prefix}-${count.index}"
  project = var.Settings.gcpProject
  zone    = element([for i in range(local.pv_disk_count) : element(local.zones, i % 3)], count.index)
}


locals {
  accessKey     = jsondecode(data.vault_generic_secret.minio_credentials.data["tarantool"]).accessKey
  secretKey     = jsondecode(data.vault_generic_secret.minio_credentials.data["tarantool"]).secretKey
  tarantoolUser = jsondecode(data.vault_generic_secret.tarantool_credentials.data.credentials).username
  tarantoolPass = jsondecode(data.vault_generic_secret.tarantool_credentials.data.credentials).password
  namespace     = var.Settings.clusters[var.Cluster].tarantool.namespace
}


resource "kubernetes_secret" "minio_credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = local.namespace
  }

  data = {
    "accesskey" = local.accessKey
    "secretkey" = local.secretKey
  }
}



resource "kubernetes_secret" "tarantool_credentials" {
  metadata {
    name      = "tarantool-creds"
    namespace = local.namespace
  }

  data = {
    "username" = local.tarantoolUser
    "password" = local.tarantoolPass
  }
}





resource "kubernetes_stateful_set" "tarantool_stateful_set" {
  metadata {
    name      = "tarantool"
    namespace = local.namespace
    labels = {
      app = "tarantool"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "tarantool"
      }
    }

    service_name = "tarantool"

    template {
      metadata {
        labels = {
          app = "tarantool"
        }

        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }

      spec {
        dynamic "affinity" {
          for_each = var.Cluster == "production" ? [var.Cluster] : []
          content {
            node_affinity {
              required_during_scheduling_ignored_during_execution {
                node_selector_term {
                  match_expressions {
                    key      = "workloadsType"
                    operator = "In"
                    values   = ["tarantool"]
                  }
                }
              }
            }
          }
        }

        toleration {
          key      = "workloadsType"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        container {
          name  = "tarantool"
          image = var.Settings.clusters[var.Cluster].tarantool.image

          volume_mount {
            name       = "tarantool-data"
            mount_path = "/var/lib/tarantool"
          }

          volume_mount {
            name       = "tarantool-opt"
            mount_path = "/opt/tarantool"
          }

          port {
            container_port = 3301
          }

          env {
            name  = "TARANTOOL_MEMTX_MEMORY"
            value = var.Settings.clusters[var.Cluster].tarantool.memtx_bytes
          }

          env {
            name  = "TT_MEMTX_USE_MVCC_ENGINE"
            value = var.Settings.clusters[var.Cluster].tarantool.use_mvcc_engine
          }

          env {
            name  = "TT_VINYL_CACHE"
            value = var.Settings.clusters[var.Cluster].tarantool.vinyl_cache_bytes
          }

          env {
            name  = "TT_VINYL_MEMORY"
            value = var.Settings.clusters[var.Cluster].tarantool.vinyl_mem_bytes
          }

          env {
            name  = "TT_READAHEAD"
            value = var.Settings.clusters[var.Cluster].tarantool.read_ahead_bytes
          }


          env {
            name = "TARANTOOL_USER_NAME"
            value_from {
              secret_key_ref {
                name = "tarantool-creds"
                key  = "username"
              }
            }
          }

          env {
            name = "TARANTOOL_USER_PASSWORD"
            value_from {
              secret_key_ref {
                name = "tarantool-creds"
                key  = "password"
              }
            }
          }

          resources {
            limits = {
              cpu    = var.Settings.clusters[var.Cluster].tarantool.cpu_limit
              memory = var.Settings.clusters[var.Cluster].tarantool.mem_limit
            }

            requests = {
              memory = var.Settings.clusters[var.Cluster].tarantool.mem_request
              cpu    = var.Settings.clusters[var.Cluster].tarantool.cpu_request
            }
          }
        }

        container {
          name  = "minio-sidecar"
          image = "minio/mc"

          args = [
            "mirror",
            "--watch",
            "--overwrite",
            "--exclude",
            "*.inprogress",
            "--remove",
            "/home/tarantool/data",
            "minio/${var.Settings.clusters[var.Cluster].tarantool.backupBucket}",
          ]


          env {
            name = "MINIO_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = "minio-credentials"
                key  = "accesskey"
              }
            }
          }

          env {
            name = "MINIO_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = "minio-credentials"
                key  = "secretkey"
              }
            }
          }

          env {
            name  = "MC_HOST_minio"
            value = "http://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@minio.minio:9000"
          }


          volume_mount {
            name       = "tarantool-data"
            mount_path = "/home/tarantool/data"
            read_only  = true
          }

        }

        # dynamic "init_container" {
        #   for_each = var.Cluster == "production" ? [var.Cluster] : []

        #   content {
        #     name  = "init-minio-sync"
        #     image = "minio/mc"
        #     args = [
        #       "mirror",
        #       "--overwrite",
        #       "--remove",
        #       "minio/${var.Settings.clusters[var.Cluster].tarantool.backupBucket}",
        #       "/home/tarantool/data",
        #     ]
        #     volume_mount {
        #       name       = "tarantool-data"
        #       mount_path = "/home/tarantool/data"
        #     }

        #     env {
        #       name = "MINIO_ACCESS_KEY"
        #       value_from {
        #         secret_key_ref {
        #           name = "minio-credentials"
        #           key  = "accesskey"
        #         }
        #       }
        #     }

        #     env {
        #       name = "MINIO_SECRET_KEY"
        #       value_from {
        #         secret_key_ref {
        #           name = "minio-credentials"
        #           key  = "secretkey"
        #         }
        #       }
        #     }

        #     env {
        #       name  = "MC_HOST_minio"
        #       value = "http://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@minio.minio:9000"
        #     }

        #   }
        # }
      }


    }

    update_strategy {
      type = "RollingUpdate"

      rolling_update {
        partition = 1
      }
    }

    volume_claim_template {
      metadata {
        name = "tarantool-opt"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "kms-encrypted"

        resources {
          requests = {
            storage = var.Settings.clusters[var.Cluster].tarantool.pvc_opt_size
          }
        }
      }
    }


    volume_claim_template {
      metadata {
        name = "tarantool-data"
      }

      # dynamic "spec" {
      #   for_each = var.Cluster == "production" ? [var.Cluster] : []
      #   content {
      #     access_modes       = ["ReadWriteOnce"]
      #     storage_class_name = "kms-encrypted"

      #     resources {
      #       requests = {
      #         storage = var.Settings.clusters[var.Cluster].tarantool.pvc_data_size
      #       }
      #     }

      #   }
      # }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = null

        selector {
          match_labels = {
            target = "tarantool-data"
          }
        }

        resources {
          requests = {
            storage = data.google_compute_disk.tarantool_data_pv[0].size
          }
        }
        volume_name = "${kubernetes_persistent_volume.tarantool_data_pv[0].metadata.0.name}"
      }
    }
  }
}



resource "kubernetes_service" "tarantool_service" {
  metadata {
    name      = "tarantool"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = "tarantool"
    }
    port {
      port        = 3301
      target_port = 3301
    }
  }
}




resource "kubernetes_persistent_volume" "tarantool_data_pv" {
  count   = local.pv_disk_count
  metadata {
    name = "${local.pv_prefix}-${count.index}-pv"
    labels = {
      target = "tarantool-data"
    }
  }
  spec {
    capacity = {
      storage = data.google_compute_disk.tarantool_data_pv[count.index].size
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.namespace
      name      = "${local.pv_prefix}-tarantool-${count.index}"
    }
    persistent_volume_source {
      csi {
        driver        = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.tarantool_data_pv[count.index].zone}/disks/${local.pv_prefix}-${count.index}"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "topology.gke.io/zone"
            operator = "In"
            values   = [data.google_compute_disk.tarantool_data_pv[count.index].zone]
          }
        }
      }
    }
  }
}
