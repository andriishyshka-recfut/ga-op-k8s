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
    "hosts.toml"           = <<-TOML
      server = "https://${local.artifactoryUrl}"

      [host."https://${local.artifactoryUrl}"]
        capabilities = ["pull", "resolve"]
        client = [["/etc/containerd/hosts.d/${local.artifactoryUrl}/client.crt", "/etc/containerd/hosts.d/${local.artifactoryUrl}/client.key"]]
    TOML
    "docker.io-hosts.toml" = <<-TOML
      server = "https://registry-1.docker.io"

      [host."https://mirror.gcr.io"]
        capabilities = ["pull", "resolve"]
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
        host_pid                         = true
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
              ROOT="/host-containerd"
              TARGET="$ROOT/hosts.d/${local.artifactoryUrl}"
              DOCKER_TARGET="$ROOT/hosts.d/docker.io"
              CONFIG="$ROOT/config.toml"
              BACKUP="$ROOT/config.toml.pre-mtls"

              CURRENT_CHECKSUM=""

              mkdir -p "$TARGET" "$DOCKER_TARGET"

              while true; do
                NEW_CHECKSUM="$(sha256sum /secret/tls.crt /secret/tls.key /config/hosts.toml /config/docker.io-hosts.toml)"

                if [ "$NEW_CHECKSUM" != "$CURRENT_CHECKSUM" ]; then
                  cp /secret/tls.crt "$TARGET/client.crt.tmp"
                  cp /secret/tls.key "$TARGET/client.key.tmp"
                  cp /config/hosts.toml "$TARGET/hosts.toml.tmp"
                  cp /config/docker.io-hosts.toml "$DOCKER_TARGET/hosts.toml.tmp"

                  chmod 0644 "$TARGET/client.crt.tmp"
                  chmod 0600 "$TARGET/client.key.tmp"
                  chmod 0644 "$TARGET/hosts.toml.tmp"
                  chmod 0644 "$DOCKER_TARGET/hosts.toml.tmp"

                  mv "$TARGET/client.crt.tmp" "$TARGET/client.crt"
                  mv "$TARGET/client.key.tmp" "$TARGET/client.key"
                  mv "$TARGET/hosts.toml.tmp" "$TARGET/hosts.toml"
                  mv "$DOCKER_TARGET/hosts.toml.tmp" "$DOCKER_TARGET/hosts.toml"

                  if ! grep -qF 'config_path = "/etc/containerd/hosts.d"' "$CONFIG"; then
                    cp -p "$CONFIG" "$BACKUP"

                    awk '
                      $0 == "[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"docker.io\"]" {
                        skip = 1
                        next
                      }
                      skip && /^\[/ {
                        skip = 0
                      }
                      !skip {
                        print
                      }
                    ' "$CONFIG" > "$CONFIG.tmp"

                    if grep -Eq '\.registry\.(mirrors|configs)\.' "$CONFIG.tmp"; then
                      echo "Another legacy registry block remains; aborting"
                      rm "$CONFIG.tmp"
                      exit 1
                    fi

                    if grep -qFx '[plugins."io.containerd.grpc.v1.cri".registry]' "$CONFIG.tmp"; then
                      echo "Registry block already exists without expected config_path; aborting"
                      rm "$CONFIG.tmp"
                      exit 1
                    fi

                    printf '\n[plugins."io.containerd.grpc.v1.cri".registry]\n  config_path = "/etc/containerd/hosts.d"\n' \
                      >> "$CONFIG.tmp"

                    chmod 0644 "$CONFIG.tmp"
                    mv "$CONFIG.tmp" "$CONFIG"
                    echo "containerd registry configuration migrated"
                  fi

                  printf '%s\n' "$NEW_CHECKSUM" > "$TARGET/.restart-required.tmp"
                  mv "$TARGET/.restart-required.tmp" "$TARGET/.restart-required"

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
                "/host-containerd/hosts.d/${local.artifactoryUrl}/hosts.toml",
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
            name       = "containerd-dir"
            mount_path = "/host-containerd"
          }
        }
        container {
          name              = "restart-containerd"
          image             = "gke.gcr.io/startup-script:v2"
          image_pull_policy = "Always"

          env {
            name  = "ADDRESS"
            value = local.artifactoryUrl
          }

          env {
            name  = "STARTUP_SCRIPT"
            value = <<-SCRIPT
              set -o errexit
              set -o pipefail
              set -o nounset

              marker="/etc/containerd/hosts.d/$ADDRESS/.restart-required"
              applied="/etc/containerd/hosts.d/$ADDRESS/.applied-checksum"
              failed="/etc/containerd/hosts.d/$ADDRESS/.failed-checksum"
              config="/etc/containerd/config.toml"
              backup="/etc/containerd/config.toml.pre-mtls"

              while true; do
                current_checksum="$(cat "$marker" 2>/dev/null || true)"
                applied_checksum="$(cat "$applied" 2>/dev/null || true)"
                failed_checksum="$(cat "$failed" 2>/dev/null || true)"

                if [[ -n "$current_checksum" &&
                      "$current_checksum" != "$applied_checksum" &&
                      "$current_checksum" != "$failed_checksum" ]]; then

                  echo "mTLS configuration changed; restarting containerd"
                  restart_ok=0

                  if systemctl restart containerd; then
                    for _ in {1..30}; do
                      if systemctl is-active --quiet containerd &&
                        [[ -S /run/containerd/containerd.sock ]]; then
                        restart_ok=1
                        break
                      fi
                      sleep 1
                    done
                  fi

                  if [[ "$restart_ok" -eq 1 ]]; then
                    printf '%s\n' "$current_checksum" > "$applied.tmp"
                    mv "$applied.tmp" "$applied"
                    rm -f "$failed"
                    echo "containerd restarted successfully"
                  else
                    echo "containerd failed; restoring previous config"

                    cp -p "$backup" "$config"
                    systemctl restart containerd

                    printf '%s\n' "$current_checksum" > "$failed.tmp"
                    mv "$failed.tmp" "$failed"

                    echo "previous containerd config restored"
                  fi
                fi

                sleep 10
              done
            SCRIPT
          }

          security_context {
            privileged = true
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
          name = "containerd-dir"

          host_path {
            path = "/etc/containerd"
            type = "Directory"
          }
        }
      }
    }
  }
}
