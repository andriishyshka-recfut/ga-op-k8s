locals {
  postInstallSteps = <<EOF
  curl -XPOST "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_license/start_trial?acknowledge=true" -k &&\
  curl -X PUT "https://elastic:$ES_PASSWORD@${local.esValues.esName}-es-http:9200/_security/role_mapping/oidc-example?pretty" -H 'Content-Type: application/json' -k -d'
{
  "roles": [ "superuser" ],
  "enabled": true,
  "rules": {
    "field": { "realm.name": "${local.oidcRealmName}" }
  }
}
'

EOF
}

resource "kubernetes_job" "post_install" {
  count = local.oidcSetup
  metadata {
    name      = "${local.esValues.esName}-post-install"
    namespace = local.esValues.namespace
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
          name    = "post-install"
          image   = "curlimages/curl"
          command = ["sh", "-c", local.postInstallSteps]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "${local.esValues.esName}-es-elastic-user"
                key  = "elastic"
              }
            }
          }
          resources {
            requests {
              cpu    = "10m"
              memory = "10M"
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
    null_resource.ansible_validate_resources
  ]
}
