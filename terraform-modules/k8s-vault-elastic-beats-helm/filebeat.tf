resource "helm_release" "filebeat" {
  name      = "filebeat"
  chart     = "${path.module}/charts/filebeat"
  wait      = true
  atomic    = true
  timeout   = 7200
  namespace = local.elasticSettings.globalSettings.namespace
  values = [
    templatefile("${path.module}/filebeat-values.tftpl", merge(local.elasticSettings.globalSettings, { kibana = var.BeatKibanaService, elastic = var.BeatElasticService, filebeat_groups = local.filebeat_groups }))
  ]
  depends_on = [
    kubernetes_job.beats_users
  ]
}

resource "kubernetes_secret" "python_script" {
  metadata {
    name      = "filebeat-script"
    namespace = "elastic"
  }
  data = {
    "filebeat.py" = "${file("${path.module}/filebeat.py")}"
  }
}

resource "kubernetes_job" "python_script" {
  metadata {
    name      = "filebeat-script"
    namespace = "elastic"
  }
  spec {
    template {
      metadata {
        annotations = {
          "sidecar.istio.io/inject" : "false"
        }
      }
      spec {
        container {
          name    = "script"
          image   = "harbor.regemini.io/op/tf:latest"
          command = ["/ansible/bin/python3", "/opt/filebeat.py"]
          # command = ["sh", "-c", "tail -f /dev/null"]
          env {
            name  = "TEMPLATES"
            value = local.filebeat_groups
          }
          env {
            name  = "FILEBEAT_VERSION"
            value = local.version
          }
          env {
            name  = "ELASTICSEARCH_USERNAME"
            value = "elastic"
          }
          env {
            name = "ELASTICSEARCH_PASSWORD"
            value_from {
              secret_key_ref {
                name = "elastic-credentials"
                key  = "elastic"
              }
            }
          }
          env {
            name  = "ELASTICSEARCH_URL"
            value = "red-coor:9200"
          }
          volume_mount {
            name       = "ca-cert"
            mount_path = "/etc/ssl"
            read_only  = "true"
          }
          volume_mount {
            name       = "script"
            mount_path = "/opt"
            read_only  = "true"
          }
        }
        volume {
          name = "ca-cert"
          secret {
            secret_name = "elastic-https-certs"
            items {
              key  = "ca.crt"
              path = "ca.crt"
            }
          }
        }
        volume {
          name = "script"
          secret {
            secret_name = "filebeat-script"
          }
        }
        image_pull_secrets {
          name = "harbor"
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  depends_on          = [kubernetes_secret.python_script, helm_release.filebeat]
}