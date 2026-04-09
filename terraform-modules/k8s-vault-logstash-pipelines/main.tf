resource "helm_release" "logstash" {
  for_each     = local.logstash_list
  name         = "logstash-${each.key}"
  namespace    = try(each.value.namespace, local.namespace)
  chart        = "${path.module}/logstash"
  wait         = true
  atomic       = true
  reset_values = true
  force_update = true
  replace      = true
  values = [
    templatefile("${path.module}/templates/logstash.tftpl",{
      name = each.key
      values = each.value
    })
  ]
  

  depends_on = [kubernetes_secret.logstash_elastic_ca, kubernetes_secret.logstash_es_creds, kubernetes_secret.minio_creds, kubernetes_manifest.tmp_logstash, kubernetes_job.logstash_user]
}

data "kubernetes_secret" "logstash_elastic_ca" {
  for_each = local.logstash_list
  metadata {
    name      = try(each.value.es_cert_secretname, local.es_cert_secretname)
    namespace = try(each.value.es_namespace, local.namespace)
  }
}

resource "kubernetes_secret" "logstash_elastic_ca" {
  for_each = local.logstash_list
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
  for_each = local.logstash_list
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
  for_each = local.logstash_list
  length   = 32
  special  = false
}

resource "vault_generic_secret" "logstash_etl_creds" {
  path = "secret/wl/etl/logstash-creds"
  data_json = jsonencode({
    "credentials.json" = { for k, v in var.logstash_list : k => { "user" : local.logstash_user, "password" : resource.random_password.logstash_api_password[k].result, "ids" : v.pipeline_id } }
  })
}

resource "kubernetes_config_map" "vandelay_reload" {
  count = var.Cluster == "production" ? 1 : 0
  metadata {
    name      = "reload"
    namespace = "vandelay"
  }
  data = {
    date = timestamp()
  }
}

resource "vault_generic_secret" "vandelay_logstash_3_creds" {
  count = var.Cluster == "production" ? 1 : 0
  path  = "secret/wl/vandelay/logstash"
  data_json = jsonencode({
    "hosts"    = "http://logstash-3.elastic:9600"
    "password" = resource.random_password.logstash_api_password["logstash-3"].result
    "username" = local.logstash_user
  })
}

resource "vault_generic_secret" "logstash_es_creds" {
  for_each = local.logstash_list
  path     = "secret/logstash/${each.key}"
  data_json = jsonencode({
    logstash_es_password  = resource.random_password.logstash_es_password.result
    logstash_es_username  = local.logstash_user
    logstash_api_password = resource.random_password.logstash_api_password[each.key].result
  })
}

data "vault_generic_secret" "logstash_es_creds" {
  for_each   = local.logstash_list
  path       = "secret/logstash/${each.key}"
  depends_on = [vault_generic_secret.logstash_es_creds]
}

resource "kubernetes_secret" "logstash_es_creds" {
  for_each = local.logstash_list
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
  for_each = local.logstash_list
  metadata {
    name      = "logstash-${each.key}-user-setup"
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
