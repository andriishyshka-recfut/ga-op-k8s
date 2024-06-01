data "vault_generic_secret" "minio_auth" {
  path = "secret/minio/users"
}

data "vault_generic_secret" "harbor_passwords_secret" {
  path = "secret/harbor"
}


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
./mc alias set backup https://minio.p.regemini.io $MINIO_ACCESS_KEY $MINIO_SECRET_KEY
./mc cat backup/minio-xbackup-orbital-wording-233917/harbor-backup/$DATE/registry.sql | psql --host=harbor-database --port=5432 --username=postgres --dbname=registry -v ON_ERROR_STOP=ON;
./mc cat backup/minio-xbackup-orbital-wording-233917/harbor-backup/$DATE/notarysigner.sql | psql --host=harbor-database --port=5432 --username=postgres --dbname=notarysigner -v ON_ERROR_STOP=ON;
./mc cat backup/minio-xbackup-orbital-wording-233917/harbor-backup/$DATE/notaryserver.sql | psql --host=harbor-database --port=5432 --username=postgres --dbname=notaryserver -v ON_ERROR_STOP=ON;
echo "Postgres restore completed";
# ./mc cat backup/minio-xbackup-orbital-wording-233917/harbor-backup/dump.rdb > /redis/dump.rdb ;
# echo "Redis restore completed";
EOF
}


resource "random_id" "rand" {
  byte_length = 8
}

resource "kubernetes_job" "harbor_restore" {
  count = 1
  metadata {
    name      = "harbor-restore-${lower(random_id.rand.hex)}"
    namespace = "harbor"
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
          image   = "postgres:14.9"
          command = ["bash", "-c", local.restoreCommand]
                env {
                name = "MINIO_ACCESS_KEY"
                value = jsondecode(data.vault_generic_secret.minio_auth.data.harbor).accessKey
                }
                env {
                name = "MINIO_SECRET_KEY"
                value = jsondecode(data.vault_generic_secret.minio_auth.data.harbor).secretKey
                }
                env {
                name  = "MC_HOST_backup"
                value = "https://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@minio.p.regemini.io"
                }          
                env {
                name = "DATE"
                value = "2024-06-01_12:29"
                }
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
  # depends_on = [
  #   helm_release.harbor,
    # null_resource.kubectl_scale_down_redis
  # ]
}
