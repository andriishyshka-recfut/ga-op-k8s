resource "helm_release" "filebeat" {
  for_each  = var.filebeats_settings
  name      = each.key
  chart     = "${path.module}/charts/filebeat"
  wait      = true
  atomic    = true
  timeout   = 7200
  namespace = each.value.namespace
  values = [
    templatefile("${path.module}/templates/helm_values/${each.key}-values.tftpl", {
      settings = each.value
      imageTag = local.filebeat_image_tags[each.key]
      color    = var.Color
      cluster  = var.Cluster
    })
  ]
  depends_on = [
    kubernetes_secret.filebeat_elastic_ca,
    kubernetes_secret.filebeat_elastic_pass
  ]
  set = [{
    name  = "priorityClassName"
    value = kubernetes_priority_class.beats.metadata.0.name
  }]
}

resource "null_resource" "workload_readiness_check" {
  for_each = var.filebeats_settings
  triggers = {
    filebeats_check    = md5(file("${path.module}/${local.filebeat_check_script_path}"))
    workload_readiness = md5(file("${path.module}/${local.workload_check_module_path}"))
  }
  provisioner "local-exec" {
    command = <<COMMAND
    python3 ../${local.filebeat_check_script_path}
COMMAND
    environment = {
      WORKLOAD_TYPE        = local.filebeat_workload_type
      WORKLOAD_NAME        = each.value.name
      WORKLOAD_NAMESPACE   = each.value.namespace
      WORKLOAD_MODULE_PATH = "../${local.workload_check_module_path}"
      CHECK_TIMEOUT        = "60"
      CHECK_RETRIES        = "15"
    }
  }
  depends_on = [
    helm_release.filebeat
  ]
}




# resource "kubernetes_secret" "python_script" {
#   for_each = local.filebeat_groups_list
#   metadata {
#     name      = "${each.key}-script"
#     namespace = each.value.namespace
#   }
#   data = {
#     "filebeat.py" = "${file("${path.module}/filebeat.py")}"
#   }
# }

# resource "kubernetes_job" "python_script" {
#   for_each = local.filebeat_groups_list
#   metadata {
#     name      = "${each.key}-script-job"
#     namespace = each.value.namespace
#   }
#   spec {
#     template {
#       metadata {
#         annotations = {
#           "sidecar.istio.io/inject" : "false"
#         }
#       }
#       spec {
#         container {
#           name    = "script"
#           image   = "harbor.regemini.io/op/tf:latest"
#           command = ["/ansible/bin/python3", "/opt/filebeat.py"]
#           env {
#             name  = "TEMPLATES"
#             value = each.value.log_groups
#           }
#           env {
#             name  = "FILEBEAT_VERSION"
#             value = local.filebeat_image_tags[each.key]
#           }
#           env {
#             name  = "ELASTICSEARCH_USERNAME"
#             value = "elastic"
#           }
#           env {
#             name = "ELASTICSEARCH_PASSWORD"
#             value_from {
#               secret_key_ref {
#                 name = each.value.elastic_pass_secretname
#                 key  = "elastic"
#               }
#             }
#           }
#           env {
#             name  = "ELASTICSEARCH_URL"
#             value = each.value.elastic_service
#           }
#           volume_mount {
#             name       = "ca-cert"
#             mount_path = "/etc/ssl"
#             read_only  = "true"
#           }
#           volume_mount {
#             name       = "script"
#             mount_path = "/opt"
#             read_only  = "true"
#           }
#         }
#         volume {
#           name = "ca-cert"
#           secret {
#             secret_name = each.value.elastic_cert_secretname
#             items {
#               key  = "ca.crt"
#               path = "ca.crt"
#             }
#           }
#         }
#         volume {
#           name = "script"
#           secret {
#             secret_name = "${each.key}-script"
#           }
#         }
#         image_pull_secrets {
#           name = "harbor"
#         }
#         restart_policy = "Never"
#       }
#     }
#     backoff_limit = 4
#   }
#   wait_for_completion = true
#   depends_on          = [kubernetes_secret.python_script, helm_release.filebeat, null_resource.workload_readiness_check]
#   timeouts {
#     create = "10m"
#     update = "10m"
#   }
# }

resource "kubernetes_priority_class" "beats" {
  metadata {
    name = "beats"
  }

  value             = 100000
  description       = "Used to place elasticsearch beats on nodes with higher priority"
  preemption_policy = "PreemptLowerPriority"
}
