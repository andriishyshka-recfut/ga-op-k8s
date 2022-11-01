data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.activeClusterVaultPath
}


data "external" "get_remote_node" {
  program = ["bash", "${path.module}/../../terraform-modules/get-k8s-internals.sh"]
  query = {
    server = data.vault_generic_secret.k8s_auth_inactive.data.HOST
    token  = data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token
  }
}

