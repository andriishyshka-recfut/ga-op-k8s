data "vault_kv_secret_v2" "artifactory_certs" {
  count = local.enableArtifactoryMtls
  mount = "secret"
  name  = "misc/artifactory/certs"
}

resource "kubernetes_secret_v1" "artifactory_client_mtls" {
  count = local.enableArtifactoryMtls

  metadata {
    name      = "artifactory-client-mtls"
    namespace = "kube-system"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = data.vault_kv_secret_v2.artifactory_certs[0].data["tls_crt"]
    "tls.key" = data.vault_kv_secret_v2.artifactory_certs[0].data["tls_key"]
  }
}

resource "kubernetes_config_map_v1" "containerd_mtls" {
  count = local.enableArtifactoryMtls

  metadata {
    name      = "containerd-mtls-config"
    namespace = "kube-system"
  }

  data = {
    "hosts.toml" = <<-TOML
      server = "https://${local.artifactoryUrl}"

      [host."https://${local.artifactoryUrl}"]
        capabilities = ["pull", "resolve"]
        client = [["/etc/containerd/hosts.d/${local.artifactoryUrl}/client.crt", "/etc/containerd/hosts.d/${local.artifactoryUrl}/client.key"]]
    TOML
  }
}
resource "kubernetes_daemon_set_v1" "containerd_mtls" {
  count = local.enableArtifactoryMtls

  metadata {
    name      = "containerd-mtls-config"
    namespace = "kube-system"

    labels = {
      app = "containerd-mtls-config"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "containerd-mtls-config"
      }
    }

    strategy {
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = {
          app = "containerd-mtls-config"
        }
      }

      spec {
        automount_service_account_token  = false
        priority_class_name              = "system-node-critical"
        termination_grace_period_seconds = 5

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        toleration {
          operator = "Exists"
        }

        container {
          name              = "configure-containerd"
          image             = "docker.io/library/busybox:1.37.0"
          image_pull_policy = "IfNotPresent"

          command = [
            "/bin/sh",
            "-eu",
            "-c",
            <<-SCRIPT
              TARGET="/host/${local.artifactoryUrl}"
              CURRENT_CHECKSUM=""

              mkdir -p "$TARGET"

              while true; do
                NEW_CHECKSUM="$(sha256sum /secret/tls.crt /secret/tls.key /config/hosts.toml)"

                if [ "$NEW_CHECKSUM" != "$CURRENT_CHECKSUM" ]; then
                  cp /secret/tls.crt "$TARGET/client.crt.tmp"
                  cp /secret/tls.key "$TARGET/client.key.tmp"
                  cp /config/hosts.toml "$TARGET/hosts.toml.tmp"

                  chmod 0644 "$TARGET/client.crt.tmp"
                  chmod 0600 "$TARGET/client.key.tmp"
                  chmod 0644 "$TARGET/hosts.toml.tmp"

                  mv "$TARGET/client.crt.tmp" "$TARGET/client.crt"
                  mv "$TARGET/client.key.tmp" "$TARGET/client.key"
                  mv "$TARGET/hosts.toml.tmp" "$TARGET/hosts.toml"

                  CURRENT_CHECKSUM="$NEW_CHECKSUM"
                  echo "containerd mTLS configuration updated"
                fi

                sleep 60
              done
            SCRIPT
          ]

          security_context {
            run_as_user                = 0
            run_as_group               = 0
            allow_privilege_escalation = false
            read_only_root_filesystem  = true

            capabilities {
              drop = ["ALL"]
            }
          }

          readiness_probe {
            exec {
              command = [
                "test",
                "-s",
                "/host/${local.artifactoryUrl}/hosts.toml",
              ]
            }

            period_seconds = 10
          }

          resources {
            requests = {
              cpu    = "5m"
              memory = "8Mi"
            }

            limits = {
              memory = "32Mi"
            }
          }

          volume_mount {
            name       = "client-certificate"
            mount_path = "/secret"
            read_only  = true
          }

          volume_mount {
            name       = "containerd-config"
            mount_path = "/config"
            read_only  = true
          }

          volume_mount {
            name       = "containerd-hosts"
            mount_path = "/host"
          }
        }

        volume {
          name = "client-certificate"

          secret {
            secret_name = kubernetes_secret_v1.artifactory_client_mtls[0].metadata[0].name
          }
        }

        volume {
          name = "containerd-config"

          config_map {
            name = kubernetes_config_map_v1.containerd_mtls[0].metadata[0].name
          }
        }

        volume {
          name = "containerd-hosts"

          host_path {
            path = "/etc/containerd/hosts.d"
            type = "DirectoryOrCreate"
          }
        }
      }
    }
  }
}
