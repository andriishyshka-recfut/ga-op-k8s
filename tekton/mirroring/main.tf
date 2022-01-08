data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}


data "external" "get_remote_node" {
  program = ["bash", "${path.module}/get-node-ip.sh"]
  query = {
    server = data.vault_generic_secret.k8s_auth_inactive.data.HOST
    token = data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token
  }
}

locals {
  yaml = replace(
                  file("${path.module}/MM2.yaml"),
                  "CHANGEME",
                  data.external.get_remote_node.result.ip
                  )
}

resource "kubectl_manifest" "mm2" {
  yaml_body  = local.yaml
}
