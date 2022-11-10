
locals {
  dataEs = yamldecode(file("elastic7_settings.yaml"))
}


data "vault_generic_secret" "elastic7_transport_ca" {
  path = "secret/elasticsearch-admin/replication"
}


resource "kubernetes_secret" "elastic7_transport_ca" {
  metadata {
    name      = "remote-certs"
    namespace = "elastic7"
  }
  data = {
    "remote.ca.crt"  = data.vault_generic_secret.elastic7_transport_ca.data.remote_ca_crt
    "remote2.ca.crt" = data.vault_generic_secret.elastic7_transport_ca.data.remote2_ca_crt
  }
  depends_on = [
    data.vault_generic_secret.elastic7_transport_ca
  ]
}


module "elastic7-elastic" {
  source                       = "../../terraform-modules/k8s-vault-elastic"
  ElasticSettings              = local.dataEs.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  StoreEsPasswordInVault       = true
  MinioAddress                 = var.Settings.clusters[var.Cluster].MinioAddress
  BackupBucketName             = "es7"
  BackupBucketBasePath         = "7"
  OidcRedirectUri              = "k.t.regemini.io"
}


module "elastic7-kibana" {
  source                       = "../../terraform-modules/k8s-vault-kibana"
  ElasticSettings              = local.dataEs.kibana1_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
  Cluster                      = var.Cluster
  Color                        = var.Color
  Settings                     = var.Settings
  depends_on = [
    module.es7-restore
  ]
}

# module "elastic7-kibana-2" {
#   source                       = "../../terraform-modules/k8s-vault-kibana"
#   ElasticSettings              = local.dataEs.kibana2_settings
#   GkeClusterConnectionSettings = local.gkeClusterConnectionSettings
#   Cluster                      = var.Cluster
#   Color                        = var.Color
#   Settings                     = var.Settings
#   depends_on = [
#     module.es7-restore
#   ]
# }

/*
module "elastic-beats" {
  source   = "../../terraform-modules/k8s-vault-elastic-beats"
  Cluster  = var.Cluster
  Color    = var.Color
  Settings = var.Settings
  # depends_on = [module.elastic-elastic]
}
*/
