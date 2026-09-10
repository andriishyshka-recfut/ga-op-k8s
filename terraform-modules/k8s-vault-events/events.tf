locals {
  elastic_url      = lookup(var.Settings.clusters[var.Cluster][var.Color].k8s-events, "elastic_url", "mon-coor.monitoring.svc.cluster.local:9200")
  events_init      = var.Settings.clusters[var.Cluster][var.Color].k8s-events.init
  events_log_level = var.Settings.clusters[var.Cluster][var.Color].k8s-events.log_level
  events_version   = var.Settings.clusters[var.Cluster].versions.k8s-events.chart_version
  events_tag       = var.Settings.clusters[var.Cluster].versions.k8s-events.tag
  events_user      = <<EOF
curl -sSk -X PUT \
  "https://elastic:$ES_PASSWORD@${local.elastic_url}/_ingest/pipeline/kube-events" -H 'Content-Type: application/json' -d '
{
  "processors": [
    {
      "set": {
        "field": "@timestamp",
        "copy_from": "_ingest.timestamp"
      }
    }
  ]
}' &&\
curl -sS -X POST "https://elastic:$ES_PASSWORD@${local.elastic_url}/_security/role/kube-events" -H 'Content-Type: application/json' -k -d  '
{
   "indices":[{"names":"kube-events*","privileges":["write","read","view_index_metadata"]}]
}' &&\
curl -sS -X POST "https://elastic:$ES_PASSWORD@${local.elastic_url}/_security/user/kube-events-${var.Cluster}" -H 'Content-Type: application/json' -k -d "
{
    \"password\": \"$ELASTIC_EVENTS_PASSWORD\",
    \"roles\": [\"kube-events\"]
}" &&\
curl -sS -X PUT "https://elastic:$ES_PASSWORD@${local.elastic_url}/_index_template/kube-events" -H 'Content-Type: application/json' -k -d '
{
  "index_patterns": ["kube-events*"],
  "data_stream": {},
  "priority": 1,
  "template": {
    "settings": {
      "index.lifecycle.name": "kube-events",
      "index.default_pipeline": "kube-events"
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "clusterName": {
          "type": "keyword"
        }
      }
    }
  }
}' &&\
curl -sS -X PUT "https://elastic:$ES_PASSWORD@${local.elastic_url}/_ilm/policy/kube-events" -H 'Content-Type: application/json' -k -d '
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
}' &&\
if ! curl -fsSk  "https://elastic:$ES_PASSWORD@${local.elastic_url}/_data_stream/kube-events" >/dev/null 2>&1; then
  curl -sSk --fail-with-body -X PUT "https://elastic:$ES_PASSWORD@${local.elastic_url}/_data_stream/kube-events"
fi
EOF

}

ephemeral "random_password" "events_password" {
  length  = 24
  special = false
}

resource "kubernetes_secret_v1" "events_creds" {
  metadata {
    name      = "events-credentials"
    namespace = local.namespace
  }

  data_wo = {
    ELASTIC_EVENTS_PASSWORD = ephemeral.random_password.events_password.result
  }
  data_wo_revision = 1
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
                name = local.elasticSecretName
                key  = "elastic"
              }
            }
          }
          env {
            name = "ELASTIC_EVENTS_PASSWORD"
            value_from {
              secret_key_ref {
                name = "events-credentials"
                key  = "ELASTIC_EVENTS_PASSWORD"
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
    kubernetes_secret_v1.events_creds
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
    templatefile("${path.module}/events_vaules.yaml.tftpl", { elastic_url = local.elastic_url, log_level = local.events_log_level, tag = local.events_tag, cluster = var.Cluster, color = var.Color })
  ]
  depends_on = [kubernetes_job.events_install]
}


