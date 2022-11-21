variable "logstash_list" {
  default = {logstash : {}}
}

locals {
  namespace     = "elastic7"
  minio_user    = "backup"
  es_host       = "https://${local.namespace}-es-http.${local.namespace}.svc:9200"
  pipeline_id   = "testing"
  poll_interval = "5s"

  minio_users   = {for k,v in { for k, v in var.logstash_list: lookup(v, "minio_user", local.minio_user) => lookup(v, "namespace", local.namespace)... }: k => distinct(v)}
  namespaces    = toset(distinct([for k, v in var.logstash_list: lookup(v, "namespace", local.namespace )]))

}
