variable "logstash_list" {
  default = {logstash : {}}
}

locals {
  namespace     = "logstash"
  es_host       = "https://elastic7-es-http.elastic7.svc:9200"
  es_user       = "elastic"
  pipeline_id   = "testing"
  poll_interval = "5s"
}