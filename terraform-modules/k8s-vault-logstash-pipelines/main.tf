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
    value = try(each.value.logstash_version, var.logstash_version)
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
  set {
    name  = "logstashJavaOpts"
    value = try(each.value.java_opts, local.java_opts)
  }

  depends_on = [kubernetes_secret.logstash_elastic_ca, kubernetes_secret.logstash_es_creds, kubernetes_secret.minio_creds, kubernetes_manifest.tmp_logstash, kubernetes_job.logstash_user]
}

data "kubernetes_secret" "logstash_elastic_ca" {
  for_each = var.logstash_list
  metadata {
    name      = try(each.value.es_cert_secretname, local.es_cert_secretname)
    namespace = try(each.value.es_namespace, local.namespace)
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

resource "random_password" "logstash_es_password" {
  length  = 32
  special = false
}

resource "random_password" "logstash_api_password" {
  for_each = var.logstash_list
  length   = 32
  special  = false
}

# resource "vault_generic_secret" "logstash_etl_creds" {
#   path     = "secret/wl/etl/logstash-creds"
#   data_json = jsonencode({
#    "credentials.json" = {for k, v in var.logstash_list : k  => { "user": local.logstash_user, "password": resource.random_password.logstash_api_password[k].result, "ids": v.pipeline_id }}
#   })
# }

resource "vault_generic_secret" "logstash_es_creds" {
  for_each = var.logstash_list
  path     = "secret/logstash/${each.key}"
  data_json = jsonencode({
    logstash_es_password  = resource.random_password.logstash_es_password.result
    logstash_es_username  = local.logstash_user
    logstash_api_password = resource.random_password.logstash_api_password[each.key].result
  })
}

data "vault_generic_secret" "logstash_es_creds" {
  for_each   = var.logstash_list
  path       = "secret/logstash/${each.key}"
  depends_on = [vault_generic_secret.logstash_es_creds]
}

resource "kubernetes_secret" "logstash_es_creds" {
  for_each = var.logstash_list
  metadata {
    name      = "${each.key}-logstash-es-creds"
    namespace = each.value.namespace
  }

  data = {
    password              = data.vault_generic_secret.logstash_es_creds[each.key].data.logstash_es_password,
    username              = data.vault_generic_secret.logstash_es_creds[each.key].data.logstash_es_username,
    logstash_api_password = data.vault_generic_secret.logstash_es_creds[each.key].data.logstash_api_password
  }
  depends_on = [data.vault_generic_secret.logstash_es_creds]
}

resource "kubernetes_job" "logstash_user" {
  for_each = var.logstash_list
  metadata {
    name      = "logstash-${each.key}-user-setup"
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
          command = ["sh", "-c", templatefile("${path.module}/setup-${var.Cluster}-user.tftpl", { password = data.vault_generic_secret.logstash_es_creds[each.key].data.logstash_es_password, es_url = each.value.es_host })]
          env {
            name = "ES_PASSWORD"
            value_from {
              secret_key_ref {
                name = try(each.value.es_creds_secret, "elastic-credentials")
                key  = try(each.value.es_user, "elastic")
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
  depends_on = [kubernetes_secret.logstash_es_creds]
}
