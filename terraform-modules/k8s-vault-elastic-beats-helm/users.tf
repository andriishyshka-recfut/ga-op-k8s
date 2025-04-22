resource "random_password" "filebeat_password" {
  for_each = var.filebeats_settings
  length   = 24
  special  = false
}

resource "random_password" "metricbeat_password" {
  length  = 24
  special = false
}

resource "random_password" "auditbeat_password" {
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
  for_each = var.logstash_list
  path     = "secret/logstash/${each.key}"
}

resource "kubernetes_secret" "filebeat_creds" {
  for_each = var.filebeats_settings
  metadata {
    name      = each.value.filebeat_pass_secretname
    namespace = each.value.namespace
  }
  data = {
    "password" = random_password.filebeat_password[each.key].result
  }
  depends_on = [random_password.filebeat_password]
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

resource "kubernetes_secret" "auditbeat_creds" {
  metadata {
    name      = "auditbeat-credentials"
    namespace = local.elasticSettings.globalSettings.namespace
  }
  data = {
    "password" = random_password.auditbeat_password.result
  }
}

locals {
  setupUser = <<EOF
curl -X PUT "https://elastic:$ES_PASSWORD@${local.BeatElasticService}:9200/_security/role/filebeat_role" -H 'Content-Type: application/json' -k -d '
{
  "cluster": ["monitor","manage_ilm","manage_ml"],
  "indices": [
    {
      "names": ["filebeat-*"],
      "privileges": ["read","write","manage"]
    }
  ]
} ' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.BeatElasticService}:9200/_security/role/metricbeat_role" -H 'Content-Type: application/json' -k -d '
{
  "cluster": ["monitor","manage_ilm"],
  "indices": [
    {
      "names": ["metricbeat-*"],
      "privileges": ["write","manage"]
    }
  ]
} ' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.BeatElasticService}:9200/_security/user/metricbeat_user" -H 'Content-Type: application/json' -k -d '
{
    "roles" : ["kibana_admin","ingest_admin","remote_monitoring_agent","metricbeat_role","remote_monitoring_collector","monitoring_user"],
    "password": "${random_password.metricbeat_password.result}"
}'  &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.BeatElasticService}:9200/_security/role/auditbeat_role" -H 'Content-Type: application/json' -k -d '
{
  "cluster": ["monitor","manage_ilm"],
  "indices": [
    {
      "names": ["auditbeat-*"],
      "privileges": ["write","manage"]
    }
  ]
} ' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.BeatElasticService}:9200/_security/user/auditbeat_user" -H 'Content-Type: application/json' -k -d '
{
    "roles" : ["kibana_admin","ingest_admin","remote_monitoring_agent","auditbeat_role"],
    "password": "${random_password.auditbeat_password.result}"
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


resource "kubernetes_job" "filebeats_users" {
  for_each = var.filebeats_settings
  metadata {
    name      = "${each.value.name}-filebeat-user"
    namespace = each.value.namespace
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
          command = ["sh", "-c", local.filebeats_jobs[each.value.name]]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = each.value.elastic_pass_secretname
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
