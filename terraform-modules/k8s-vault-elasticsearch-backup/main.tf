
resource "random_id" "rand" {
  byte_length = 8
}

locals {
  cm = "config-curator-${lower(random_id.rand.hex)}"
  job = "job-curator-${lower(random_id.rand.hex)}"
  backupCommand = <<EOT
set -e;
curator --config /curator/config.yml /curator/actions.yml ;
EOT
}


resource "kubernetes_config_map" "curator" {
  metadata {
    name = local.cm
    namespace = var.Namespace
  }

  data = {
    "config.yml" = "${file("${path.module}/config.yaml")}"
    "actions.yml" = "${file("${path.module}/actions.yaml")}"
  }
}



resource "kubernetes_job" "es_backup" {
  metadata {
    name      = local.job
    namespace = var.Namespace
  }
  spec {
    template {
      metadata{
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
          image   = "bitnami/elasticsearch-curator"
          command = ["bash", "-c", local.backupCommand]
          volume_mount {
            name = "curator"
            mount_path = "/curator"
          }
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "${var.ElasticName}-es-elastic-user"
                key  = "elastic"
              }
            }
          }
          env {
            name  = "ES_HOST"
            value = "${var.ElasticName }-es-http"
          }
        }
        restart_policy = "Never"
      }
    }

    backoff_limit = 3
  }
  wait_for_completion = true
  timeouts {
    create = "20m"
    update = "20m"
  }
}
