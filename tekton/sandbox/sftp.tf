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
                {
                  "mountPath" = "/etc/ssh/sshd_config"
                  "name"      = "sftp-sshd"
                  "readOnly"  = true
                  "subPath"   = "sshd_config"
                },
                {
                  "mountPath" = "/home/user/.ssh/keys/"
                  "name"      = "sftp-user-key"
                  "readOnly"  = true
                },
                {
                  "mountPath" = "/home/user3/.ssh/keys/"
                  "name"      = "sftp-user2-key"
                  "readOnly"  = true
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
            {
              "configMap" = {
                "name" = "sftp-sshd"
              }
              "name" = "sftp-sshd"
            },
            {
              "name" = "sftp-user-key"
              "secret" = {
                "items" = [
                  {
                    "key"  = "id_rsa.pub"
                    "path" = "id_rsa.pub"
                  },
                ]
                "secretName" = "sftp-pub-key"
              }
            },
            {
              "name" = "sftp-user2-key"
              "secret" = {
                "items" = [
                  {
                    "key"  = "id_rsa.pub"
                    "path" = "id_rsa.pub"
                  },
                ]
                "secretName" = "sftp-pub-key"
              }
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
      user::1001
      user2:password:1001
      user3:password:1001
      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name"      = "sftp-users"
      "namespace" = "camel-k"
    }
  }
}

resource "kubernetes_manifest" "configmap_camel_k_sftp_sshd" {
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "sshd_config" = <<-EOT
      Protocol 2
      HostKey /etc/ssh/ssh_host_ed25519_key
      HostKey /etc/ssh/ssh_host_rsa_key
      UseDNS no
      PermitRootLogin no
      X11Forwarding no
      AllowTcpForwarding no
      Subsystem sftp internal-sftp
      ForceCommand internal-sftp
      ChrootDirectory %h
      Match User user3
        AuthenticationMethods publickey,password
      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name"      = "sftp-sshd"
      "namespace" = "camel-k"
    }
  }
}

resource "kubernetes_manifest" "secret_camel_k_sftp_pub_key" {
  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "id_rsa.pub" = "c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFCZ1FDNkEzVE9aZlpNQlZ0MEZWNnRtT1VacUd5a0NWcE9iWkJDQmh1K0dCVW9pb0M3WktEYW9DZk5CdWovRnpCVzNQQW9qM0F1UU11RUh0K3d2a3lGWUU0bU4vdUI5dkluT08ybVBzU3MvMVFZV2RiRkVLamkxaEdEY1BHcFNZUGJiQUcwQTVFVU9HZGxHWU1jV0tnZlM5SlVDZVJYc0hrR0lOZmRqemNpVDlMR1paZ1kvVnpGYnBMcE1iQUN2R09sOFlYOFN6VlRxK3NST1JVQTZDTnZoempNaXVDeDRaMHVRSDU5eFVndmRRTTl0Q0VrYjEzSG5JMGJEYU5pOTUxTEYxY3NsemIrRUdlSkFIc2tnOU05clFRdzB1VmwzSGFRKyt0YTV6OWhqQ0FGVzY2Z3hPUFp3NTdkbDA0bjkxNjJNd2ZnTjZ3L1AzRHM2cnBxYzBaQXNmOU84UmROUlExWTIxZ2ZnTGo1SVBNRmJqSnMxU3N4S0ZaUnNBQUF1dk1PR1lYQjVYM3hxRTQ5ZVJxdjhrRHlZaFZUdWF6OWpIbjBuS2JjRDFuZDMxNmhDbiszWkNrUGRFejlkZGoydWFCM0c4bjV3NERHc1Z0djF3dVlTN2pBWHVSeE1YZ2RGRy9uOXpLU3UrSFB4TUpFdXkySTluMWFEb1lybnFXVGNhWHh2YWs9IGRteXRyb2t1Ym92QE1hY0Jvb2stUHJvLURteXRyby5sb2NhbAo="
    }
    "kind" = "Secret"
    "metadata" = {
      "name"      = "sftp-pub-key"
      "namespace" = "camel-k"
    }
  }
}
