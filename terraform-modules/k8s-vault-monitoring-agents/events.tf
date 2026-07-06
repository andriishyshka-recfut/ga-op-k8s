locals {
  elastic_prefix   = "mon"
  events_init      = var.Settings.clusters[var.Cluster][var.Color].k8s-events.init
  events_log_level = var.Settings.clusters[var.Cluster][var.Color].k8s-events.log_level
  events_version   = var.Settings.clusters[var.Cluster].versions.k8s-events.chart_version
  events_tag       = var.Settings.clusters[var.Cluster].versions.k8s-events.tag
  events_user      = <<EOF
curl -X POST "https://elastic:$ES_PASSWORD@${local.elastic_prefix}-es-http:9200/_security/role/kube-events" -H 'Content-Type: application/json' -k -d  '
{
   "indices":[{"names":"kube-events*","privileges":["write","read","view_index_metadata"]}]
}' &&\
curl -X POST "https://elastic:$ES_PASSWORD@${local.elastic_prefix}-es-http:9200/_security/user/kube-events" -H 'Content-Type: application/json' -k -d '
{
    "password": "${random_password.events_password.result}",
    "roles": ["kube-events"]
}' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.elastic_prefix}-es-http:9200/_index_template/kube-events" -H 'Content-Type: application/json' -k -d '
{
  "index_patterns": ["kube-events*"],
  "data_stream": {},
  "priority": 1,
  "template": {
    "settings": {
      "index.lifecycle.name": "kube-events"
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        }
      }
    }
  }
}' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.elastic_prefix}-es-http:9200/_ilm/policy/kube-events" -H 'Content-Type: application/json' -k -d '
{
    "policy" : {
        "phases" : {
            "hot" : {
                "min_age" : "0ms",
                "actions" : {
                    "rollover" : {
                        "max_primary_shard_size" : "50gb",
                        "max_age" : "1d"
                    },
                    "set_priority" : {
                        "priority" : 100
                    }
                }
            },
            "delete" : {
                "min_age" : "90d",
                "actions" : {
                    "delete" : {
                        "delete_searchable_snapshot" : 'true'
                    }
                }
            }
        }
    }
}'
EOF

}

resource "random_password" "events_password" {
  length  = 24
  special = false
}

resource "kubernetes_secret" "events_creds" {
  metadata {
    name      = "events-credentials"
    namespace = local.namespace
  }
  data = {
    "ELASTIC_EVENTS_PASSWORD" = random_password.events_password.result
  }
}

resource "kubernetes_job" "events_install" {
  metadata {
    name      = "events-install"
    namespace = local.namespace
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
          command = ["sh", "-c", local.events_user]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "mon-es-elastic-user"
                key  = "elastic"
              }
            }
          }
          resources {
            requests = {
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
    kubernetes_secret.events_creds
  ]
  timeouts {
    create = "5m"
    update = "5m"
  }
}

data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}


resource "helm_release" "k8s_events" {
  name                = "kubernetes-event-exporter"
  chart               = "kubernetes-event-exporter"
  repository          = "oci://harbor.regemini.io/helm/charts"
  version             = local.events_version
  namespace           = local.namespace
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
  wait                = true
  atomic              = true
  recreate_pods       = true
  values = [
    templatefile("${path.module}/events_vaules.yaml.tftpl", { elastic_prefix = local.elastic_prefix, log_level = local.events_log_level, tag = local.events_tag })
  ]
  depends_on = [kubernetes_job.events_install]
}


