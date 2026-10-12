resource "random_password" "kibana_password" {
  length  = 24
  special = false
}

data "kubernetes_secret" "elastic_pass" {
  metadata {
    name      = "elastic-credentials"
    namespace = local.globalSettings.namespace
  }
}

resource "kubernetes_secret" "kibana_creds" {
  for_each = local.kibanaSettings
  metadata {
    name      = "kibana-${each.key}-credentials"
    namespace = each.value.namespace
  }
  data = {
    "KIBANA_PASSWORD" = random_password.kibana_password.result
  }
}

resource "kubernetes_secret" "kibana_elastic_user" {
  for_each = local.kibanaSettings
  metadata {
    name      = "kibana-${each.key}-elastic-probe"
    namespace = each.value.namespace
  }

  data = {
    ELASTICSEARCH_USERNAME = "elastic"
    ELASTICSEARCH_PASSWORD = data.kubernetes_secret.elastic_pass.data.elastic
  }
}

resource "kubernetes_secret" "kibana_es_credentials" {
  for_each = local.kibanaSettings
  metadata {
    name      = "kibana-${each.key}-es-credentials"
    namespace = each.value.namespace
  }

  data = {
    username = "elastic"
    password = data.kubernetes_secret.elastic_pass.data.elastic
  }
}

locals {
  setupUser = <<EOF
curl -X PUT "https://elastic:$ES_PASSWORD@${local.httpServive}:9200/_security/user/kibana_system/_password" -H 'Content-Type: application/json' -k -d '
{
    "password": "${random_password.kibana_password.result}"
}
'
EOF
}

resource "kubernetes_job" "kibana_user" {
  metadata {
    name      = "${local.globalSettings.clusterName}-kibana-user"
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
          name    = "post-install"
          image   = "curlimages/curl"
          command = ["sh", "-c", local.setupUser]
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
  timeouts {
    create = "5m"
    update = "5m"
  }
}
