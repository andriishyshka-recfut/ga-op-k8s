
resource "null_resource" "kubectl_scale_down_redis" {
  count = local.restoreSwitcher
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  --insecure-skip-tls-verify=true \
     --namespace ${local.harborNs} scale statefulset/harbor-harbor-redis  --replicas=0
COMMAND
  }
  depends_on = [
    helm_release.harbor
  ]
}

locals {
  restoreCommand = <<EOF
set -e;
apt-get update -q && apt-get install wget redis-tools -yq ;
wget --quiet  https://dl.min.io/client/mc/release/linux-amd64/mc ;
chmod +x mc ;
psql --host=harbor-harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "SELECT pg_terminate_backend(pg_stat_activity.pid)
  FROM pg_stat_activity
  WHERE datname = 'notarysigner'
  AND pid <> pg_backend_pid();" ;
psql --host=harbor-harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "SELECT pg_terminate_backend(pg_stat_activity.pid)
  FROM pg_stat_activity
  WHERE datname = 'notaryserver'
  AND pid <> pg_backend_pid();" ;
psql --host=harbor-harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "SELECT pg_terminate_backend(pg_stat_activity.pid)
  FROM pg_stat_activity
  WHERE datname = 'registry'
  AND pid <> pg_backend_pid();" ;
psql --host=harbor-harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "drop database if exists registry";
psql --host=harbor-harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "drop database if exists notarysigner";
psql --host=harbor-harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "drop database if exists notaryserver";
psql --host=harbor-harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "create database registry";
psql --host=harbor-harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "create database notarysigner";
psql --host=harbor-harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "create database notaryserver ";
./mc cat backup/minio-xbackup-ardent-rarity-239115/harbor-backup/registry.sql | psql --host=harbor-harbor-database --port=5432 --username=postgres --dbname=registry -v ON_ERROR_STOP=ON;
./mc cat backup/minio-xbackup-ardent-rarity-239115/harbor-backup/notarysigner.sql | psql --host=harbor-harbor-database --port=5432 --username=postgres --dbname=notarysigner -v ON_ERROR_STOP=ON;
./mc cat backup/minio-xbackup-ardent-rarity-239115/harbor-backup/notaryserver.sql | psql --host=harbor-harbor-database --port=5432 --username=postgres --dbname=notaryserver -v ON_ERROR_STOP=ON;
echo "Postgres restore completed";
./mc cat backup/minio-xbackup-ardent-rarity-239115/harbor-backup/dump.rdb > /redis/dump.rdb ;
echo "Redis restore completed";
EOF
}

resource "kubernetes_job" "harbor_restore" {
  count = local.restoreSwitcher
  metadata {
    name      = "harbor-restore"
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
    #     affinity {
    #   pod_affinity {
    #     required_during_scheduling_ignored_during_execution {
    #       label_selector {
    #         match_expressions {
    #           key      = "component"
    #           operator = "In"
    #           values   = ["redis"]
    #         }
    #       }
    #       topology_key = "topology.kubernetes.io/zone"
    #     }
    #   }
    # }

        volume {
          name = "redis"
          persistent_volume_claim {
            claim_name = "data-harbor-harbor-redis-0"
          }
        }
        container {
          name    = "restore"
          image   = "postgres:9.6"
          command = ["bash", "-c", local.restoreCommand]
          volume_mount {
            name = "redis"
            mount_path = "/redis"
          }
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
           name = "DATE"
           value = formatdate("DD-MMM-YYYY-hh", timestamp())
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
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 1
  }
  wait_for_completion = true
  timeouts {
    create = "11m"
    update = "10m"
  }
  depends_on = [
    helm_release.harbor,
    null_resource.kubectl_scale_down_redis
  ]
}

resource "null_resource" "kubectl_restart_registry" {
  count = local.restoreSwitcher
  triggers = {
    # playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
    job_id = kubernetes_job.harbor_restore[0].id
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  --insecure-skip-tls-verify=true \
     --namespace ${local.harborNs} scale statefulset/harbor-harbor-redis --replicas=1 &&\
    kubectl --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  --insecure-skip-tls-verify=true \
     --namespace ${local.harborNs} delete po  -l component=registry
COMMAND
  }
  depends_on = [
    kubernetes_job.harbor_restore,
  ]
}
