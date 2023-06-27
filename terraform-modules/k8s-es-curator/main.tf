
resource "random_id" "rand" {
  byte_length = 8
  prefix      = "curator-"
}

locals {
  cm            = "config-curator-${lower(random_id.rand.hex)}"
  job           = "${var.NamePrefix}-${lower(random_id.rand.hex)}"
  backupCommand = ["--config", "/.curator/config.yml", "/.curator/actionfile.yml"]
}

resource "kubernetes_config_map" "curator" {
  metadata {
    name      = local.cm
    namespace = var.Namespace
  }

  data = {
    "config.yml"  = "${file("${path.module}/config.yaml")}"
    "actionfile.yml" = var.Actions
  }
}



resource "kubernetes_job" "es_restore" {
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
          config_map {
            name = local.cm
          }
        }
        container {
          name    = "curator"
          image   = "bitnami/elasticsearch-curator-archived"
          command = ["bash", "-c", local.backupCommand]
        terraform-modules/k8s-es-curator/main.tf
          volume_mount {
            name       = "curator"
            mount_path = "/.curator/config.yml"
            sub_path = "config.yml"
          }
          volume_mount {
            name       = "curator"
            mount_path = "/.curator/actionfile.yml"
            sub_path = "actionfile.yml"
          }
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.EsCreds
                key  = "elastic"
              }
            }
          }
          env {
            name  = "ES_HOST"
            value = var.EsService
          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 1
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
