
resource "random_id" "rand" {
  byte_length = 8
  prefix      = "curator-"
}

locals {
  cm            = "config-curator-${lower(random_id.rand.hex)}"
  job           = "${var.NamePrefix}-${lower(random_id.rand.hex)}"
  backupCommand = <<EOT
set -e;
sleep 30;
curator --config /curator/config.yml /curator/actions.yml ;
EOT
}

# resource "kubernetes_config_map" "curator" {
#   metadata {
#     name      = local.cm
#     namespace = var.Namespace
#   }

#   data = {
#     "config.yml"     = "${file("${path.module}/config.yaml")}"
#     "actionfile.yml" = var.Actions
#   }
# }
data "kubernetes_secret" "es_creds" {
  metadata {
    name = var.EsCreds
    namespace = var.Namespace
  }
  
}

resource "kubernetes_secret" "curator_config" {
  metadata {
    name      = local.cm
    namespace = var.Namespace
  }

  data = {
    "config.yml" = templatefile("${path.module}/config.yaml", {
      ES_HOST      = local.es_host
      ES_PASSWORD = data.kubernetes_secret.es_creds.data["elastic"]
    })
    "actionfile.yml" = var.Actions
  }
}

resource "kubernetes_job" "es_backup_and_restore" {
  metadata {
    name      = local.job
    namespace = var.Namespace
  }
  spec {
    template {
      metadata {
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        volume {
          name = "curator"
          secret {
            secret_name = local.cm
          }
        }
        container {
          name  = "curator"
          image = "untergeek/curator:8.0.21"
          # command = ["bash", "-c", local.backupCommand]
          args = ["--config", "/.curator/config.yml", "/.curator/actionfile.yml"]
          volume_mount {
            name       = "curator"
            mount_path = "/.curator"

          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 0
  }
  wait_for_completion = true
  timeouts {
    create = "70m"
    update = "70m"
  }
  depends_on = [
    kubernetes_job.minio_snapshot_storage
  ]
}
