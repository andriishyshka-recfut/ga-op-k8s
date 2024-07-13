data "vault_generic_secret" "elastic_license" {
  path = local.globalSettings.license.vault_path
}

resource "kubernetes_secret" "elastic_license" {
  metadata {
    name      = "elastic-license"
    namespace = local.globalSettings.namespace
  }
  data = {
    "license.json" = data.vault_generic_secret.elastic_license.data[local.globalSettings.license.name]
  }
}
locals {
  licenceInstall = <<EOF
  curl -X POST "https://elastic:$ES_PASSWORD@${local.httpServive}:9200/_license" -H 'Content-Type: application/json' -k -d '
  ${data.vault_generic_secret.elastic_license.data[local.globalSettings.license.name]}
  '
EOF
}

resource "kubernetes_job" "license_install" {
  metadata {
    name      = "${local.globalSettings.clusterName}-license-install"
    namespace = local.globalSettings.namespace
  }
  spec {
    template {
      metadata {

        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
      spec {
        container {
          name    = "license-install"
          image   = "curlimages/curl"
          command = ["sh", "-c", local.licenceInstall]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "elastic-credentials"
                key  = "elastic"
              }
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "100M"
            }
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  depends_on = [
    helm_release.elastic,
    kubernetes_secret.elastic_license
  ]
  timeouts {
    create = "5m"
    update = "5m"
  }
}
