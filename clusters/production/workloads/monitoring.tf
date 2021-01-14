


locals {
  es = yamldecode(file("monitoring_elastic_settings.yaml"))
  gkeClusterConnectionSettings = {
    HOST                   = data.vault_generic_secret.k8s_auth.data.HOST
    API_KEY                = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  }
}


module "monitoring-elastic" {
  source                       = "../../../terraform-modules/k8s-vault-elasticsearch"
  ElasticSettings              = local.es.elastic_settings
  GkeClusterConnectionSettings = local.gkeClusterConnectionSettings

  StoreEsPasswordInVault = false
}

# module "monitoring-agents" {
#   source     = "../../../terraform-modules/k8s-monitoring-agents"
#   depends_on = [module.monitoring-elastic]
# }
