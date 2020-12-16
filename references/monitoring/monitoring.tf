

data "google_service_account" "vault-sa" {
  account_id = var.settings.clusters.sandbox.persistent_resources.vault_service_account_id
}

resource "google_service_account_key" "es-key" {
  service_account_id = data.google_service_account.vault-sa.name
}


locals {
  es = yamldecode(file("elastic_settings.yaml"))
  gke_cluster_connection_settings = {
    HOST                   = data.vault_generic_secret.k8s_auth.data.HOST
    API_KEY                = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  }
}


module "monitoring-elastic" {
  source                          = "../../../terraform-modules/k8s-elasticsearch"
  elastic_settings                = local.es.elastic_settings
  gke_cluster_connection_settings = local.gke_cluster_connection_settings
  backup_sa_private_key           = google_service_account_key.es-key.private_key
  store_es_password_in_vault      = false
}

module "monitoring-agents" {
  source     = "../../../terraform-modules/k8s-monitoring-agents"
  depends_on = [module.monitoring-elastic]
}
