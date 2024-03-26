resource "helm_release" "logstash" {
  for_each     = var.logstash_list
  name         = "logstash-${each.key}"
  namespace    = try(each.value.namespace, local.namespace)
  chart        = "${path.module}/logstash"
  wait         = true
  atomic       = true
  reset_values = true
  force_update = true
  replace      = true
  values = [
    file("${path.module}/logstash/values.yaml")
  ]
  set {
    name  = "fullnameOverride"
    value = each.key
  }
  set {
    name  = "elastic.namespace"
    value = try(each.value.namespace, local.namespace)
  }
  set {
    name  = "imageTag"
    value = try(each.value.logstash_version, local.logstash_version)
  }
  set {
    name  = "elastic.host"
    value = try(each.value.es_host, local.es_host)
  }
  set {
    name  = "elastic.pipelineID"
    value = try(each.value.pipeline_id, local.pipeline_id)
  }
  set {
    name  = "elastic.pollInterval"
    value = try(each.value.poll_interval, local.poll_interval)
  }
  set {
    name  = "elastic.cluster_uuid"
    value = try(each.value.cluster_uuid, local.cluster_uuid)
  }
  set {
    name  = "minio.user"
    value = try(each.value.minio_user, local.minio_user)
  }
  set {
    name  = "minio.endpoint"
    value = try(each.value.minio_endpoint, local.minio_endpoint)
  }
  set {
    name  = "minio.bucket"
    value = try(each.value.minio_bucket, local.minio_bucket)
  }
  set {
    name  = "mountCaCert.volumeName"
    value = "${each.key}-logstash-https-certs"
  }
  set {
    name  = "extraVolumes[0].name"
    value = "tmp-logstash-${each.key}"
  }
  set {
    name  = "extraVolumes[0].persistentVolumeClaim.claimName"
    value = "tmp-logstash-${each.key}"
  }
  set {
    name  = "extraVolumeMounts[0].name"
    value = "tmp-logstash-${each.key}"
  }
  set {
    name  = "log_level"
    value = try(each.value.log_level, local.log_level)
  }
  set {
    name  = "resources.requests.cpu"
    value = try(each.value.cpu_request, local.cpu_request)
  }
  set {
    name  = "resources.requests.memory"
    value = try(each.value.mem_request, local.mem_request)
  }
  set {
    name  = "resources.limits.cpu"
    value = try(each.value.cpu_limit, local.cpu_limit)
  }
  set {
    name  = "resources.limits.memory"
    value = try(each.value.mem_limit, local.mem_limit)
  }

  depends_on = [kubernetes_secret.logstash_elastic_ca, kubernetes_secret.logstash_es_creds, kubernetes_secret.minio_creds, kubernetes_manifest.tmp_logstash, kubernetes_job.logstash_user]
}

# Stuck point, if you want run logstash on another namespace than elastic
data "kubernetes_secret" "logstash_elastic_ca" {
  for_each = var.logstash_list
  metadata {
    name      = each.value.elastic_cert_secretname
    namespace = each.value.elastic_namespace
  }
}

resource "kubernetes_secret" "logstash_elastic_ca" {
  for_each = var.logstash_list
  metadata {
    name      = "${each.key}-logstash-https-certs"
    namespace = each.value.namespace
  }
  data       = data.kubernetes_secret.logstash_elastic_ca[each.key].data
  depends_on = [data.kubernetes_secret.logstash_elastic_ca]
}


data "vault_generic_secret" "minio_creds" {
  path = "secret/minio/users"
}

resource "kubernetes_secret" "minio_creds" {
  for_each = var.logstash_list
  metadata {
    name      = "${each.key}-logstash-minio-creds"
    namespace = each.value.namespace
  }
  data = {
    access_key = jsondecode(data.vault_generic_secret.minio_creds.data[each.value.minio_user]).accessKey,
    secret_key = jsondecode(data.vault_generic_secret.minio_creds.data[each.value.minio_user]).secretKey
  }
  depends_on = [data.vault_generic_secret.minio_creds]
}

locals {
  logstash_user = "logstash"
  logstash_password = random_password.logstash_password.result
  setupSandboxUser = <<EOF
curl -X PUT "https://elastic:$ES_PASSWORD@${local.es_url}:9200/_security/role/logstash_sandbox" -H 'Content-Type: application/json' -k -d '
{
  "indices": [
    {
      "names": ["added*","pans*","creds*"],
      "privileges": ["read"]
    }
  ]
} ' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.es_url}/_security/role/logstash_writer" -H 'Content-Type: application/json' -k -d '
{
  "cluster": ["manage_index_templates","monitor","manage_ilm"],
  "indices": [
    {
      "names": ["logstash*"],
      "privileges": ["write","create","create_index","manage","manage_ilm"]
    }
  ]
} ' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.es_url}/_security/role/logstash_reader" -H 'Content-Type: application/json' -k -d '
{
  "cluster": ["manage_logstash_pipelines"],
  "indices": [
    {
      "names": ["logstash*"],
      "privileges": ["read","view_index_metadata"]
    }
  ]
} ' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.es_url}/_security/role/logstash_admin" -H 'Content-Type: application/json' -k -d '
{
  "cluster": ["manage_logstash_pipelines"],
  "indices": [
    {
      "names": [".logstash*"],
      "privileges": ["create","delete","index","manage","read"]
    }
  ]
} ' &&\
curl -X PUT "https://elastic:$ES_PASSWORD@${local.es_url}/_security/user/logstash" -H 'Content-Type: application/json' -k -d '
{
    "roles" : ["","logstash_writer","logstash_reader","logstash_admin"],
    "password": "${local.logstash_passwd}"
}'
EOF
}

resource "random_password" "logstash_password" {
  length  = 32
  special = false
}

resource "kubernetes_job" "logstash_user" {
  metadata {
    name      = "es-logstash-user-setup"
    namespace = local.es_creds_ns
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
          command = ["sh", "-c", var.Cluster == "production" ? local.setupProdUser : local.setupSandboxUser]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = local.es_creds_creds
                key  = local.es_creds_ns
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
