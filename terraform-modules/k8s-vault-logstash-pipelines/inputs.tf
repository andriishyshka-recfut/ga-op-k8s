variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

variable "logstash_list" {
  default = { logstash : {} }
}

locals {
  namespace        = "elastic"
  es_creds_secret  = "elastic_credentials"
  es_creds_ns      = "elastic"
  logstash_version =  var.Settings.clusters[var.Cluster][var.Color].versions.logstash.logstash_version

  minio_user       = "logstash-red"
  minio_endpoint   = "https://minio.regemini.io"
  minio_bucket     = "minio-logstash-pipelines-orbital-wording-233917"
  es_host          = "https://red-coor.${local.namespace}.svc:9200"
  es_url           = element(split("/", local.es_host), length(split("/", local.es_host)) -1)
  pipeline_id      = "testing"
  cluster_uuid     = "gOn3ZMirSsyBqRx7koiPOQ"
  poll_interval    = "5s"
  log_level        = "info"
  cpu_request      = "100m"
  mem_request      = "256Mi"
  cpu_limit        = "400m"
  mem_limit        = "512Mi"

  minio_users      = { for k, v in { for k, v in var.logstash_list : lookup(v, "minio_user", local.minio_user) => lookup(v, "namespace", local.namespace)... } : k => distinct(v) }
  namespaces       = toset(distinct([for k, v in var.logstash_list : lookup(v, "namespace", local.namespace)]))

  logstash_user    = "logstash"
  logstash_passwd  = random_password.logstash_password.result
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
    "roles" : ["logstash_writer","logstash_reader","logstash_admin","logstash_sandbox"],
    "password": "${local.logstash_password}"
}'
EOF
  setupProdUser = <<EOF
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
    "roles" : ["_minionRO_","_domeRO_","_pansRO_","_cryptoRO_","gForum","_cppRO_","_magecartRO_","_maidRO_","_checkerRO_","logstash_writer","logstash_reader","logstash_admin"],
    "password": "${local.logstash_password}"
}'
EOF
}
