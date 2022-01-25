

locals {
  restoreCommand = <<EOF
set -e;
apt-get update -q && apt-get install wget redis-tools -yq ;
wget --quiet  https://dl.min.io/client/mc/release/linux-amd64/mc ;
chmod +x mc ;
psql --host=harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "SELECT pg_terminate_backend(pg_stat_activity.pid)
  FROM pg_stat_activity
  WHERE datname = 'notarysigner'
  AND pid <> pg_backend_pid();" ;
psql --host=harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "SELECT pg_terminate_backend(pg_stat_activity.pid)
  FROM pg_stat_activity
  WHERE datname = 'notaryserver'
  AND pid <> pg_backend_pid();" ;
psql --host=harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "SELECT pg_terminate_backend(pg_stat_activity.pid)
  FROM pg_stat_activity
  WHERE datname = 'registry'
  AND pid <> pg_backend_pid();" ;
psql --host=harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "drop database if exists registry";
psql --host=harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "drop database if exists notarysigner";
psql --host=harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "drop database if exists notaryserver";
psql --host=harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "create database registry";
psql --host=harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "create database notarysigner";
psql --host=harbor-database --port=5432 --username=postgres -v ON_ERROR_STOP=ON -d template1 -c "create database notaryserver ";
./mc cat backup/minio-xbackup-ardent-rarity-239115/harbor-backup/registry.sql | psql --host=harbor-database --port=5432 --username=postgres --dbname=registry -v ON_ERROR_STOP=ON;
./mc cat backup/minio-xbackup-ardent-rarity-239115/harbor-backup/notarysigner.sql | psql --host=harbor-database --port=5432 --username=postgres --dbname=notarysigner -v ON_ERROR_STOP=ON;
./mc cat backup/minio-xbackup-ardent-rarity-239115/harbor-backup/notaryserver.sql | psql --host=harbor-database --port=5432 --username=postgres --dbname=notaryserver -v ON_ERROR_STOP=ON;
echo "Postgres restore completed";
# ./mc cat backup/minio-xbackup-ardent-rarity-239115/harbor-backup/dump.rdb > /redis/dump.rdb ;
# echo "Redis restore completed";
EOF
}


resource "random_id" "rand" {
  byte_length = 8
}

resource "kubernetes_job" "harbor_restore" {
  count = local.restoreSwitcher
  metadata {
    name      = "harbor-restore-${lower(random_id.rand.hex)}"
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
        container {
          name    = "restore"
          image   = "postgres:13.3"
          command = ["bash", "-c", local.restoreCommand]
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
          # env {
          #   name = "DATE"
          #   value = formatdate("DD-MMM-YYYY-hh", timestamp())
          # }
          env {
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = "harbor-database"
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
    # null_resource.kubectl_scale_down_redis
  ]
}
