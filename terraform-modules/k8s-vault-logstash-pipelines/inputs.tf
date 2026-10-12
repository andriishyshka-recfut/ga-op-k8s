variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

variable "logstash_list" {
  default = { logstash : {} }
}
variable "logstash_version" {}
variable "RepositoryDomain" {}

locals {
  es_user             = "elastic"
  es_creds_secretname = "elastic-credentials"
  es_cert_secretname  = "elastic-https-certs"
  namespace           = "elastic"
  minio_user          = "logstash-red"
  minio_endpoint      = "http://minio:9000"
  minio_bucket        = "minio-logstash-pipelines-orbital-wording-233917"
  es_host             = "red-coor.${local.namespace}.svc.cluster.local:9200"
  pipeline_id         = "testing"
  cluster_uuid        = "gOn3ZMirSsyBqRx7koiPOQ"
  poll_interval       = "5s"
  log_level           = "info"
  cpu_request         = "1400m"
  mem_request         = "256Mi"
  cpu_limit           = "1100m"
  mem_limit           = "1700Mi"
  java_opts           = "-Xmx4g -Xms4g"

  minio_users = { for k, v in { for k, v in var.logstash_list : lookup(v, "minio_user", local.minio_user) => lookup(v, "namespace", local.namespace)... } : k => distinct(v) }
  namespaces  = toset(distinct([for k, v in var.logstash_list : lookup(v, "namespace", local.namespace)]))

  logstash_user = "logstash"
  vault_url = var.Color == "red" ? "https://vault.p.regemini.io" : "http://vault-active.vault:8200"   

  logstash_list = { for name, value  in var.logstash_list : name => merge(local.valuesDefault, value)}
  artifactory_repo = "${var.RepositoryDomain}/ga-op-docker-local"

  valuesDefault = {
    namespace = local.namespace
    logstash_version = var.logstash_version
    es_host = local.es_host
    pipeline_id = local.pipeline_id
    poll_interval = local.poll_interval
    cluster_uuid = local.cluster_uuid
    minio_user = local.minio_user
    minio_endpoint = local.minio_endpoint
    minio_bucket = local.minio_bucket
    log_level = local.log_level
    cpu_request = local.cpu_request
    mem_request = local.mem_request
    cpu_limit = local.cpu_limit
    mem_limit = local.mem_limit
    java_opts = local.java_opts
  }
  mongo_secret_template = [
    { k8s_key = "username", vault_key = "username"},
    { k8s_key = "password", vault_key = "token"}
  ]
}

