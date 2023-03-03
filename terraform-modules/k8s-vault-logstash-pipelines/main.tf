resource "helm_release" "logstash" {
  for_each     = var.logstash_list
  name         = each.key
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
    name  = "minio.user"
    value = try(each.value.minio_user, local.minio_user)
  }
  set {
    name = "minio.endpoint"
    value = try(each.value.minio_endpoint, local.minio_endpoint)
  }
  set {
    name = "minio.bucket"
    value = try(each.value.minio_bucket, local.minio_bucket)
  }

  depends_on = [kubernetes_secret.logstash_elastic_ca,kubernetes_secret.logstash_es_creds,kubernetes_secret.minio_creds]
}


data "kubernetes_secret" "logstash_elastic_ca" {
  for_each = local.namespaces
  metadata {
    name      = "${each.key}-https-certs"
    namespace = each.key
  }
}

resource "kubernetes_secret" "logstash_elastic_ca" {
  for_each = local.namespaces
  metadata {
    name      = "${each.key}-logstash-https-certs"
    namespace = each.key
  }
  data = data.kubernetes_secret.logstash_elastic_ca[each.key].data
}


data "vault_generic_secret" "minio_creds" {
  path         = "secret/minio/users"
}

resource "kubernetes_secret" "minio_creds" {
  for_each = local.minio_users
  metadata {
    name      = "${each.key}-logstash-minio-creds"
    namespace = each.value[0]
  }
  data = {
    access_key = jsondecode(data.vault_generic_secret.minio_creds.data[each.key]).accessKey,
    secret_key = jsondecode(data.vault_generic_secret.minio_creds.data[each.key]).secretKey
  }
}


data "vault_generic_secret" "logstash_es_creds" {
  path      = "secret/logstash/red"
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#"
}

resource "kubernetes_secret" "logstash_es_creds" {
  for_each = local.namespaces
  metadata {
    name       = "${each.key}-logstash-es-creds"
    namespace  = each.key
  }

  data = {
    password   = data.vault_generic_secret.logstash_es_creds.data.password,
    username   = data.vault_generic_secret.logstash_es_creds.data.username,
    logstash_password   = random_password.password.result
  }
}