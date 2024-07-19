variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

variable "logstash_list" {
  default = { logstash : {} }
}
variable "logstash_version" {}
locals {
  es_user             = "elastic"
  es_creds_secretname = "elastic-credentials"
  es_cert_secretname  = "elastic-https-certs"
  namespace           = "elastic"
  minio_user          = "logstash-red"
  minio_endpoint      = "https://minio.regemini.io"
  minio_bucket        = "minio-logstash-pipelines-orbital-wording-233917"
  es_host             = "red-coor.${local.namespace}.svc:9200"
  pipeline_id         = "testing"
  cluster_uuid        = "gOn3ZMirSsyBqRx7koiPOQ"
  poll_interval       = "5s"
  log_level           = "info"
  cpu_request         = "100m"
  mem_request         = "256Mi"
  cpu_limit           = "800m"
  mem_limit           = "1536Mi"
  java_opts           = "-Xmx4g -Xms4g"

  minio_users = { for k, v in { for k, v in var.logstash_list : lookup(v, "minio_user", local.minio_user) => lookup(v, "namespace", local.namespace)... } : k => distinct(v) }
  namespaces  = toset(distinct([for k, v in var.logstash_list : lookup(v, "namespace", local.namespace)]))

  logstash_user = "logstash"
}
