locals {
  report_prefix = "${local.clusterName}-nightly-${local.version}"
}


resource "kubernetes_config_map" "scan_settings" {
  metadata {
    name = "scan-settings"
    namespace = local.namespace
  }

  data = {
    "controls-inputs.json" = "${file("${path.module}/controls-inputs.json")}"
    "exceptions.json" = "${file("${path.module}/exceptions.json")}"
  }

}


resource "kubernetes_cron_job_v1" "nightly_scan" {
  metadata {
    name      = "nightly-kubescape-scan"
    namespace = "kubescape"
  }

  spec {
    schedule = "0 2 * * *"
    job_template {
      metadata {
        name = "nightly-kubescape-job"
        namespace = "kubescape"
      }

      spec {
        template {
        metadata {}
          spec {
            service_account_name = "kubescape"
            init_container {
              name  = "init-mc"
              image = "alpine:latest"
              command = [ "sh", "-c" ]
              args = [
                "cd /home/nonroot/results/ && wget https://dl.min.io/client/mc/release/linux-amd64/mc && chmod +x ./mc"
              ]
              volume_mount {
                name      = "results"
                mount_path = "/home/nonroot/results"
              }
              volume_mount {
                name       = "mc-config"
                mount_path = "/home/nonroot/.mc"
              }
            }
            container {
              name    = "kubescape"
              image   = "quay.io/kubescape/kubescape-cli:${local.version}"
              command = [ "sh", "-c" ]
              args = [
                 <<-EOT
                      kubescape scan framework nsa,mitre,cis-v1.10.0,allcontrols --exclude-namespaces kubescape,kube-system,gmp-system --format json,html --keep-local -o /home/nonroot/results/${local.report_prefix}_$(date +%d-%m-%Y_%H%m) --controls-config /home/nonroot/config/controls-inputs.json --exceptions /home/nonroot/config/exceptions.json
                      /home/nonroot/results/mc cp /home/nonroot/results/*.json minio/${local.minioBucket}/
                      /home/nonroot/results/mc cp /home/nonroot/results/*.html minio/${local.minioBucket}/
                  EOT
              ]
              resources {
                limits = {
                  cpu    = "2700m"
                  memory = "1024Mi"
                }
                requests = {
                  cpu    = "2000m"
                  memory = "600Mi"
                }
              }
              env {
                name = "MINIO_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = "minio-credentials"
                    key  = "accesskey"
                  }
                }
              }
              env {
                name = "MINIO_SECRET_KEY"
                value_from {
                  secret_key_ref {
                    name = "minio-credentials"
                    key  = "secretkey"
                  }
                }
              }
              env {
                name  = "MC_HOST_minio"
                value = "https://$(MINIO_ACCESS_KEY):$(MINIO_SECRET_KEY)@minio-red.minio-mng.svc.cluster.local:9000"
              }
              env {
                name  = "MC_CONFIG_DIR"
                value = "/home/nonroot/.mc"
              }
              volume_mount {
                name       = "results"
                mount_path = "/home/nonroot/results"
              }
              volume_mount {
                name       = "mc-config"
                mount_path = "/home/nonroot/.mc"
              }
              volume_mount {
                name       = "scan-settings"
                mount_path = "/home/nonroot/config"
              }
              volume_mount {
                name       = "mc-ca"
                mount_path = "/home/nonroot/.mc/certs/CAs"
                read_only = true
              }
            }
            restart_policy = "OnFailure"
            volume {
              name = "results"
              empty_dir {}
            }
            volume {
              name = "mc-config"
              empty_dir {}
            }
            volume {
              name = "scan-settings"
              config_map {
                name = "scan-settings"
              }
            }
            volume {
              name = "mc-ca"
              secret {
                secret_name = "minio-credentials"
                items {
                  key = "ca.crt"
                  path = "ca.crt"
                }
              }
            }
          }
        }
      }
    }
  }
}


# namespace = "kubescape"
# kubescape scan --exclude-namespaces kubescape,kube-system --format html --keep-local

# /*
# Flags:
#       --access-key string                      Kubescape SaaS access key. Default will load access key from cache
#       --account string                         Kubescape SaaS account ID. Default will load account ID from cache
#       --cluster-name string                    Set the custom name of the cluster. Not same as the kube-context flag
#       --compliance-threshold float32           Compliance threshold is the percent below which the command fails and returns exit code 1
#       --controls-config string                 Path to an controls-config obj. If not set will download controls-config from ARMO management portal
#       --exceptions string                      Path to an exceptions obj. If not set will download exceptions from ARMO management portal
#   -e, --exclude-namespaces exclude-namespace   Namespaces to exclude from scanning. e.g: --exclude-namespaces ns-a,ns-b. Notice, when running with exclude-namespace kubescape does not scan cluster-scoped objects.
#   -f, --format string                          Output file format. Supported formats: "pretty-printer", "json", "junit", "prometheus", "pdf", "html", "sarif" (default "pretty-printer")
#   -h, --help                                   help for scan
#       --include-namespaces string              scan specific namespaces. e.g: --include-namespaces ns-a,ns-b
#       --keep-local                             If you do not want your Kubescape results reported to configured backend.
#       --kubeconfig string                      Paths to a kubeconfig. Only required if out-of-cluster.
#   -o, --output string                          Output file. Print output to file and not stdout
#       --scan-images                            Scan resources images
#       --severity-threshold string              Severity threshold is the severity of failed controls at which the command fails and returns exit code 1
#       --submit                                 Submit the scan results to Kubescape SaaS where you can see the results in a user-friendly UI, choose your preferred compliance framework, check risk results history and trends, manage exceptions, get remediation recommendations and much more. By default the results are not submitted
#       --use-artifacts-from string              Load artifacts from local directory. If not used will download them
#       --use-default                            Load local policy object from default path. If not used will download latest
#       --use-from strings                       Load local policy object from specified path. If not used will download latest
#   -v, --verbose                                Display all of the input resources and not only failed resources
#       --view string                            View results based on the resource/control/security. default is --view=security (default "security")

# Global Flags:
#       --cache-dir string      Cache directory [$KS_CACHE_DIR] (default "/Users/the.legend/.kubescape")
#       --disable-color         Disable color output for logging
#       --enable-color          Force enable color output for logging
#       --kube-context string   Kube context. Default will use the current-context
#   -l, --logger string         Logger level. Supported: debug/info/success/warning/error/fatal [$KS_LOGGER] (default "info")
#       --server string         Backend discovery server URL

# */
