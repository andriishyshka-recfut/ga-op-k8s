
locals {
  backupCommand = <<EOF
  set -e ;
  apt-get update -q && apt-get install wget  redis-tools -yq ;
  wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc ;
  chmod +x mc ;
  pg_dump --host=harbor-database --port=5432 --username=postgres --dbname=registry   |  ./mc pipe backup/minio-xbackup-orbital-wording-233917/harbor-backup/registry.sql ;
  pg_dump --host=harbor-database --port=5432 --username=postgres --dbname=notarysigner  |  ./mc pipe backup/minio-xbackup-orbital-wording-233917/harbor-backup/notarysigner.sql ;
  pg_dump --host=harbor-database --port=5432 --username=postgres --dbname=notaryserver  |  ./mc pipe backup/minio-xbackup-orbital-wording-233917/harbor-backup/notaryserver.sql ;

EOF
}

data "vault_generic_secret" "minio_auth" {
  path = "secret/minio/users"
}

resource "random_id" "rand" {
  byte_length = 8
}

resource "kubernetes_job" "harbor_backup" {
  metadata {
    name      = "harbor-backup-${lower(random_id.rand.hex)}"
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
          name    = "dump"
          image   = "postgres:13.3"
          command = ["bash", "-c", local.backupCommand]
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
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = "harbor-database"
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
          env {
            name  = "DATE"
            value = formatdate("DD-MMM-YYYY-hh", timestamp())
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
