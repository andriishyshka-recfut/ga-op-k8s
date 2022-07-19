#Ugly but work for compatible with legacy

locals {
  k8s_sa_token              = data.kubernetes_secret.cluster_admin_creds.data["token"]
  kubernetes-production-red = merge(var.GkeClusterConnectionSettings, { k8s_sa_token = local.k8s_sa_token })
}
resource "vault_generic_secret" "cluster_token" {
  path      = "secret/kubernetes-production-red"
  data_json = jsonencode(local.kubernetes-production-red)
}

data "vault_generic_secret" "cluster_token" {
  path = "secret/kubernetes-production-red"
}
