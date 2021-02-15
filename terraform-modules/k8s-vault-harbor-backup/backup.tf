
locals {
  backupCommand = <<EOF
  set -e ;
  apt-get update -q && apt-get install wget  redis-tools -yq ;
  wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc ;
  chmod +x mc ;
  pg_dump --host=harbor-harbor-database --port=5432 --username=postgres --dbname=registry   |  ./mc pipe backup/minio-xbackup-${local.currentProject}/harbor-backup/registry.sql ;
  pg_dump --host=harbor-harbor-database --port=5432 --username=postgres --dbname=notarysigner  |  ./mc pipe backup/minio-xbackup-${local.currentProject}/harbor-backup/notarysigner.sql ;
  pg_dump --host=harbor-harbor-database --port=5432 --username=postgres --dbname=notaryserver  |  ./mc pipe backup/minio-xbackup-${local.currentProject}/harbor-backup/notaryserver.sql ;
  redis-cli -h harbor-harbor-redis  SAVE ;
  cat /redis/dump.rdb |  ./mc pipe backup/minio-xbackup-${local.currentProject}/harbor-backup/dump.rdb
EOF
}

resource "kubernetes_job" "harbor_backup" {
  metadata {
    name      = "harbor-backup"
    namespace = local.harborNs
  }
  spec {
    template {
      metadata {
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        affinity {
      pod_affinity {
        required_during_scheduling_ignored_during_execution {
          label_selector {
            match_expressions {
              key      = "component"
              operator = "In"
              values   = ["redis"]
            }
          }
          topology_key = "topology.kubernetes.io/zone"
        }
      }
    }

        volume {
          name = "redis"
          persistent_volume_claim {
            claim_name = "data-harbor-harbor-redis-0"
          }
        }
        container {
          name    = "dump"
          image   = "postgres:9.6"
          command = ["bash", "-c", local.backupCommand]
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
            name  = "MC_HOST_backup"
            value = "http://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@minio.minio:9000"
          }
          env {
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = "harbor-harbor-database"
                key  = "POSTGRES_PASSWORD"
              }
            }

          }
          volume_mount {
            name = "redis"
            mount_path = "/redis"
          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 1
  }
  wait_for_completion = true
  timeouts {
    create = "10m"
    update = "10m"
  }
}
