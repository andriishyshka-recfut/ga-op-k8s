data "kubernetes_secret" "gcs-credentials" {
  metadata {
    name      = "gcs-credentials"
    namespace = "monitoring"
  }
}

locals {
  es = yamldecode(file("crypto_elastic_settings.yaml"))
  gke_cluster_connection_settings = {
    HOST                   = data.vault_generic_secret.k8s_auth.data.HOST
    API_KEY                = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  }
}
module "maid-elastic" {
  source                          = "../../../terraform-modules/k8s-elasticsearch"
  elastic_settings                = local.es.elastic_settings
  gke_cluster_connection_settings = local.gke_cluster_connection_settings
  backup_sa_private_key           = base64encode(lookup(data.kubernetes_secret.gcs-credentials.data, "gcs.client.default.credentials_file"))
  store_es_password_in_vault      = false
  depends_on                      = [kubernetes_namespace.ns]
}
