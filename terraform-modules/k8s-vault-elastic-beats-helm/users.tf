resource "random_password" "filebeat_password" {
  length  = 24
  special = false
}

resource "random_password" "metricbeat_password" {
  length  = 24
  special = false
}

data "kubernetes_secret" "elastic_pass" {
  metadata {
    name      = "elastic-credentials"
    namespace = local.elasticSettings.globalSettings.namespace
  }
}

data "vault_generic_secret" "logstash_es_creds" {
  for_each  = var.logstash_pipelines
  path      = "secret/logstash/${local.elasticSettings.globalSettings.clusterName}"
}

resource "kubernetes_secret" "filebeat_creds" {
  metadata {
    name      = "filebeat-credentials"
    namespace = local.elasticSettings.globalSettings.namespace
  }
  data = {
    "password" = random_password.filebeat_password.result
  }
}

resource "kubernetes_secret" "metricbeat_creds" {
  metadata {
    name      = "metricbeat-credentials"
    namespace = local.elasticSettings.globalSettings.namespace
  }
  data = {
    "password" = random_password.metricbeat_password.result
  }
}

locals {
  setupUser = <<EOF
curl -X PUT "https://elastic:$ES_PASSWORD@${var.BeatElasticService}:9200/_security/role/filebeat_role" -H 'Content-Type: application/json' -k -d '
{
  "cluster": ["monitor","manage_ilm","manage_ml"],
  "indices": [
    {
      "names": ["filebeat-*"],
      "privileges": ["read","write","manage"]
    }
  ]
} ' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${var.BeatElasticService}:9200/_security/role/metricbeat_role" -H 'Content-Type: application/json' -k -d '
{
  "cluster": ["monitor","manage_ilm"],
  "indices": [
    {
      "names": ["metricbeat-*"],
      "privileges": ["write","manage"]
    }
  ]
} ' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${var.BeatElasticService}:9200/_security/user/filebeat_user" -H 'Content-Type: application/json' -k -d '
{
    "roles" : ["kibana_admin","ingest_admin","remote_monitoring_agent","filebeat_role"],
    "password": "${random_password.filebeat_password.result}"
}'  &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${var.BeatElasticService}:9200/_security/user/metricbeat_user" -H 'Content-Type: application/json' -k -d '
{
    "roles" : ["kibana_admin","ingest_admin","remote_monitoring_agent","metricbeat_role"],
    "password": "${random_password.metricbeat_password.result}"
}'
EOF
}

resource "kubernetes_job" "beats_users" {
  metadata {
    name      = "${local.elasticSettings.globalSettings.clusterName}-beats-user"
    namespace = local.elasticSettings.globalSettings.namespace
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
