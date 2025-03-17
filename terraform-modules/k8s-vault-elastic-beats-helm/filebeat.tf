resource "helm_release" "filebeat" {
  name      = "filebeat"
  chart     = "${path.module}/charts/filebeat"
  wait      = true
  atomic    = true
  timeout   = 7200
  namespace = local.elasticSettings.globalSettings.namespace
  values = [
    templatefile("${path.module}/filebeat-values.tftpl", merge(local.elasticSettings.globalSettings, { kibana = var.BeatKibanaService, elastic = var.BeatElasticService, filebeat_groups = var.filebeat_groups }))
  ]
  depends_on = [
    kubernetes_job.beats_users
  ]
  set {
    name  = "priorityClassName"
    value = kubernetes_priority_class.beats.metadata.0.name
  }
}

resource "null_resource" "workload_readiness_check" {
  count = length(var.filebeat_groups) > 0 ? 1 : 0
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
      WORKLOAD_NAMESPACE   = local.elasticSettings.globalSettings.namespace
      WORKLOAD_MODULE_PATH = "../${local.workload_check_module_path}"
      CHECK_TIMEOUT        = "360"
      CHECK_RETRIES        = "10"
    }
  }
  depends_on = [
    helm_release.filebeat
  ]
}

resource "kubernetes_secret" "python_script" {
  count = length(var.filebeat_groups) > 0 ? 1 : 0
  metadata {
    name      = "${helm_release.filebeat.name}-script"
    namespace = local.elasticSettings.globalSettings.namespace
  }
  data = {
    "filebeat.py" = "${file("${path.module}/filebeat.py")}"
  }
}

resource "kubernetes_job" "python_script" {
  count = length(var.filebeat_groups) > 0 ? 1 : 0
  metadata {
    name      = "${helm_release.filebeat.name}-script-job"
    namespace = local.elasticSettings.globalSettings.namespace
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
          env {
            name  = "TEMPLATES"
            value = var.filebeat_groups
          }
          env {
            name  = "FILEBEAT_VERSION"
            value = local.elasticSettings.globalSettings.imageTag
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
            value = "${local.elasticSettings.globalSettings.clusterName}-coor:9200"
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
            secret_name = "${helm_release.filebeat.name}-script"
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
  depends_on          = [kubernetes_secret.python_script, helm_release.filebeat, null_resource.workload_readiness_check]
  timeouts {
    create = "10m"
    update = "10m"
  }
}

resource "kubernetes_priority_class" "beats" {
  metadata {
    name = "beats"
  }

  value = 100000
  description = "Used to place elasticsearch beats on nodes with higher priority"
  preemption_policy = "PreemptLowerPriority"
}
