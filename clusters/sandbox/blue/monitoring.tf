

locals {
  es = yamldecode(file("elastic_settings.yaml"))
}

data "google_service_account" "vault-sa" {
  account_id = var.settings.clusters.sandbox.persistent_resources.vault_service_account_id
}

resource "google_service_account_key" "es-key" {
  service_account_id = data.google_service_account.vault-sa.name
}


module "monitoring-elastic" {
  source                          = "../../../terraform-modules/k8s-elasticsearch"
  elastic_settings                = local.es.elastic_settings
  gke_cluster_connection_settings = module.gke-setup-blue.gke_cluster_connection_settings
  backup_sa_private_key           = google_service_account_key.es-key.private_key
  store_es_password_in_vault      = false
  depends_on                      = [module.gke-setup-blue, module.k8s-istio]
}
