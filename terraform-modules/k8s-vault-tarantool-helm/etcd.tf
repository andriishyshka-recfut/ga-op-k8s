data "vault_generic_secret" "etcd_creds" {
  path = "secret/vortex/etcd"
}

resource "helm_release" "etcd" {
  name      = "etcd"
  wait      = true
  atomic    = true
  namespace = local.namespace
  timeout   = 300
  version   = "9.7.5-api-v2"
  chart               = "oci://harbor.regemini.io/helm/etcd" # based on "oci://registry-1.docker.io/bitnamicharts/etcd"
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password

  set {
    name  = "auth.rbac.rootPassword"
    value = data.vault_generic_secret.etcd_creds.data.password
  }

  set {
    name  = "initialClusterState"
    value = "new"
  }

  depends_on = [kubernetes_persistent_volume_claim.tarantool_etcd_pvc]
}
