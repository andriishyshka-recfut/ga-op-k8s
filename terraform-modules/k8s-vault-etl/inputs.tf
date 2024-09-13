variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "SecretPath" {
  default = "wl/etl"
}

# data "vault_generic_secret" "clients" {
#   # for_each = nonsensitive(local.projects)
#   for_each = local.clients
#   path     = "secret/${var.SecretPath}/clients/${each.value}"
# }

data "vault_kv_secrets_list_v2" "etl_clients_list" {
  mount = "secret"
  name  = "${var.SecretPath}/clients"
}


locals {
  clients   = nonsensitive(toset(data.vault_kv_secrets_list_v2.etl_clients_list.names))
  namespace = "etl"
  observerTag = var.Settings.clusters[var.Cluster].versions.etl.observer_tag
  operatorTag = var.Settings.clusters[var.Cluster].versions.etl.operator_tag
  ansibleScriptsTag = var.Settings.clusters[var.Cluster].versions.etl.ansible_scripts_tag
  caminoTag = var.Settings.clusters[var.Cluster].versions.etl.camino_tag
  gs2s3Tag = var.Settings.clusters[var.Cluster].versions.etl.gs2s3_tag
  elasticCertsPath = "secret/es-creds-compose-prod"
  elasticSecretsPrefix = var.Cluster == "production" ? "" : "-ext"
  elasticSecretsPath = var.Cluster == "production" ? "/secret/data/es-creds-compose-prod/metaCamino" : "/secret/data/elasticsearch-admin/elastic7-v2"


  minio_endpoints = jsonencode({
    old = {
      name   = "OG"
      url    = "minio.minio:9000"
      secure = false
      bucket = "minio-logstash-pipelines-orbital-wording-233917"
    }
    new = {
      name   = "NG"
      url    = "minio-tenant-hl.minio-helm.svc.cluster.local:9000"
      secure = true
      bucket = "etl-logstash-feeds"
    }
  })

}

