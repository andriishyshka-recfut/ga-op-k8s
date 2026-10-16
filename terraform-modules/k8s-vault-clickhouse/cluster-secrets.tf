ephemeral "vault_kv_secret_v2" "cluster" {
  mount = local.vault_mount
  name  = local.vault_cluster_path
}

resource "kubernetes_secret_v1" "cluster" {
  metadata {
    name      = local.cluster_secret_name
    namespace = local.namespace
  }

  data_wo = {
    for key in [
      "interserver-password", "management-password", "keeper-identity",
      "cluster-secret", "named-collections-key",
    ] : key => tostring(ephemeral.vault_kv_secret_v2.cluster.data[key])
  }
  data_wo_revision = 1
  type             = "Opaque"

  depends_on = [terraform_data.configuration_validation]
}
