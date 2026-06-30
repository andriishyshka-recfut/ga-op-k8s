variable "Settings" {}
variable "Color" {}
variable "Cluster" {}

resource "helm_release" "beat" {
  name      = "beats"
  chart     = "${path.module}/beats"
  wait      = true
  atomic    = true
  namespace = local.namespace
  values = [
    templatefile("${path.module}/beats_values.yaml.tftpl", { filebeat_groups = local.filebeat_groups, priority_class = kubernetes_priority_class.monitoring_beats.metadata.0.name, cluster = var.Cluster, color = var.Color })
  ]
  set = [
    {
      name  = "beatsVersion"
      value = local.version
    }
  ]
}

resource "kubernetes_priority_class" "monitoring_beats" {
  metadata {
    name = "monitoring-beats"
  }

  value = 100000
  description = "Used to place monitoring beats on nodes with higher priority"
  preemption_policy = "PreemptLowerPriority"
}

resource "null_resource" "workload_readiness_check" {

  triggers = {
    filebeats_check = md5(file("${path.module}/${local.filebeat_check_script_path}"))
    workload_readiness = md5(file("${path.module}/${local.workload_check_module_path}"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    python3 ../${local.filebeat_check_script_path}
COMMAND
    environment = {
      WORKLOAD_TYPE        = local.filebeat_workload_type
      WORKLOAD_NAME        = local.filebeat_workload_name
      WORKLOAD_NAMESPACE   = local.namespace
      WORKLOAD_MODULE_PATH = "../${local.workload_check_module_path}"
      CHECK_TIMEOUT        = "120"
      CHECK_RETRIES        = "10"
    }
  }
  depends_on = [
    helm_release.beat
  ]
}


resource "kubernetes_secret" "python_script" {
  metadata {
    name      = "filebeat-script"
    namespace = local.namespace
  }
  data = {
    "filebeat.py" = "${file("${path.module}/filebeat.py")}"
  }
}

resource "kubernetes_job" "python_script" {
  metadata {
    name      = "filebeat-script"
    namespace = local.namespace
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
          image   = "harbor.regemini.io/op/opentofu:latest"
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
                name = "mon-es-elastic-user"
                key  = "elastic"
              }
            }
          }
          env {
            name  = "ELASTICSEARCH_URL"
            value = "mon-es-http:9200"
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
            secret_name = "mon-es-cert"
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
  depends_on          = [kubernetes_secret.python_script, helm_release.beat]
}