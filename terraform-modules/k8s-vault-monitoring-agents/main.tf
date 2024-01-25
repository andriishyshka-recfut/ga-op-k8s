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
    templatefile("${path.module}/beats_values.yaml.tftpl", { filebeat_groups = local.filebeat_groups })
  ]
  set {
    name  = "beatsVersion"
    value = local.version
  }

}

resource "kubernetes_secret" "filebeats_check_script" {
  metadata {
    name      = "filebeats-check"
    namespace = local.namespace
  }
  data = {
    "filebeats_check.py" = "${file("${path.module}/filebeats_check.py")}"
  }
}

resource "kubernetes_secret" "workload_readiness_script" {
  metadata {
    name      = "workload-readiness"
    namespace = local.namespace
  }
  data = {
    "workload-readiness.py" = "${file("${path.root}/../../../references/workload-check/workload-readiness.py")}"
  }
}

resource "kubernetes_service_account" "filebeats_check_sa" {
  metadata {
    name = "filebeats-check-sa"
    namespace = local.namespace
  }
  secret {
    name = "${kubernetes_secret.filebeats_check_sa_secret.metadata.0.name}"
  }
}

resource "kubernetes_secret" "filebeats_check_sa_secret" {
  metadata {
    name = "filebeats-check-sa-secret"
    namespace = local.namespace
  }
}

resource "kubernetes_role" "filebeats_check_role" {
  metadata {
    name = "filebeats-check"
    namespace = local.namespace
    labels = {
      job = "filebeats-check"
    }
  }

  rule {
    api_groups     = ["apps"]
    resources      = ["daemonsets/status"]
    resource_names = ["${local.filebeat_workload_name}"]
    verbs          = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "filebeats_check_rolebinding" {
  metadata {
    name      = "filebeats_check_rolebinding"
    namespace = local.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.filebeats_check_role.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.filebeats_check_sa.metadata.0.name
    namespace = local.namespace
  }
}
resource "kubernetes_job" "filebeats_check_script" {
  metadata {
    name      = "filebeats-check-job"
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
          image   = "harbor.regemini.io/op/tf:latest"
          command = ["/ansible/bin/python3", "/opt/filebeats_check.py"]
          env {
            name  = "WORKLOAD_TYPE"
            value = local.filebeat_workload_type
          }
          env {
            name  = "WORKLOAD_NAME"
            value = local.filebeat_workload_name
          }
          env {
            name = "WORKLOAD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name  = "CHECK_TIMEOUT"
            value = "60"
          }
          env {
            name  = "CHECK_RETRIES"
            value = "10"
          }
          volume_mount {
            name       = "scripts"
            mount_path = "/opt"
            read_only  = "true"
          }
        }
          volume {
            name = "scripts"
            projected {
              sources {
                secret {
                  name = "filebeats-check"
                  }
                secret {
                  name = "workload-readiness"
                  }
                }
              }
            }
        service_account_name = kubernetes_service_account.filebeats_check_sa.metadata.0.name
        image_pull_secrets {
          name = "harbor"
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  depends_on          = [kubernetes_secret.filebeats_check_script, helm_release.beat, kubernetes_role_binding.filebeats_check_rolebinding]
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
  depends_on          = [kubernetes_secret.python_script, helm_release.beat, kubernetes_job.filebeats_check_script]
}
