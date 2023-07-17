
# data "vault_generic_secret" "elastic7_transport_ca" {
#   path = "secret/elasticsearch-admin/replication"
# }


# resource "kubernetes_secret" "elastic7_transport_ca" {
#   metadata {
#     name      = "remote-certs"
#     namespace = "elastic7"
#   }
#   data = {
#     "remote.ca.crt"  = data.vault_generic_secret.elastic7_transport_ca.data.remote_ca_crt
#     "remote2.ca.crt" = data.vault_generic_secret.elastic7_transport_ca.data.remote2_ca_crt
#   }
#   depends_on = [
#     data.vault_generic_secret.elastic7_transport_ca
#   ]
# }


module "elastic" {
  source                 = "../../terraform-modules/k8s-vault-elastic-helm"
  ElasticSettings        = local.ElasticSettings
  Cluster                = var.Cluster
  Color                  = var.Color
  Settings               = var.Settings
  StoreEsPasswordInVault = true
  MinioAddress           = var.Settings.clusters[var.Cluster].MinioAddress
  BackupBucketName       = "es7"
  BackupBucketBasePath   = "7"
  OidcRedirectUri        = "k.t.regemini.io"
}


module "kibana" {
  source          = "../../terraform-modules/k8s-vault-kibana-helm"
  ElasticSettings = local.ElasticSettings
  KibanaSettings  = local.KibanaSettings
  Cluster         = var.Cluster
  Color           = var.Color
  Settings        = var.Settings
  #depends_on = [
  #  module.es7-restore
  #]
}

module "elastic-beats" {
  source             = "../../terraform-modules/k8s-vault-elastic-beats-helm"
  ElasticSettings    = local.ElasticSettings
  BeatKibanaService  = "kb-ga"
  BeatElasticService = "elasticsearch-coor.elastic.svc"
  logstash_list = var.Settings.clusters[var.Cluster][var.Color].logstash
  # depends_on         = [module.kibana]
}

