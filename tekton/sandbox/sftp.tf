resource "kubernetes_manifest" "deployment_camel_k_sftp" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "Deployment"
    "metadata" = {
      "labels" = {
        "app" = "sftp"
      }
      "name"      = "sftp"
      "namespace" = "camel-k"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "sftp"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "sftp"
          }
        }
        "spec" = {
          "containers" = [
            {
              "image"           = "atmoz/sftp"
              "imagePullPolicy" = "Always"
              "name"            = "sftp-server"
              "ports" = [
                {
                  "containerPort" = 22
                },
              ]
              "volumeMounts" = [
                {
                  "mountPath" = "/etc/sftp/users.conf"
                  "name"      = "sftp-users"
                  "readOnly"  = true
                  "subPath"   = "users.conf"
                },
              ]
            },
          ]
          "volumes" = [
            {
              "configMap" = {
                "name" = "sftp-users"
              }
              "name" = "sftp-users"
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "service_camel_k_sftp" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "name"      = "sftp"
      "namespace" = "camel-k"
    }
    "spec" = {
      "ports" = [
        {
          "port"       = 22
          "protocol"   = "TCP"
          "targetPort" = 22
        },
      ]
      "selector" = {
        "app" = "sftp"
      }
    }
  }
}

resource "kubernetes_manifest" "configmap_camel_k_sftp_users" {
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "users.conf" = <<-EOT
      user:password:1001

      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name"      = "sftp-users"
      "namespace" = "camel-k"
    }
  }
}
