variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

variable "logstash_list" {
  default = { logstash : {} }
}

locals {
  namespace        = "elastic"
  logstash_version =  var.Settings.clusters[var.Cluster][var.Color].versions.logstash.logstash_version

  minio_user       = "logstash-red"
  minio_endpoint   = "https://minio.regemini.io"
  minio_bucket     = "minio-logstash-pipelines-orbital-wording-233917"
  es_host          = "https://red-coor.${local.namespace}.svc:9200"
  pipeline_id      = "testing"
  cluster_uuid     = "gOn3ZMirSsyBqRx7koiPOQ"
  poll_interval    = "5s"
  log_level        = "info"
  cpu_request      = "100m"
  mem_request      = "256Mi"
  cpu_limit        = "400m"
  mem_limit        = "512Mi"

  minio_users = { for k, v in { for k, v in var.logstash_list : lookup(v, "minio_user", local.minio_user) => lookup(v, "namespace", local.namespace)... } : k => distinct(v) }
  namespaces  = toset(distinct([for k, v in var.logstash_list : lookup(v, "namespace", local.namespace)]))

}
