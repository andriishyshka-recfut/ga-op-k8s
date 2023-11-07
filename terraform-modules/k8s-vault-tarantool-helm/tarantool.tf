data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

data "vault_generic_secret" "cartridge_creds" {
  path = "secret/vortex/cartridge"
}



resource "helm_release" "tarantool_operator" {
  name      = "tarantool-operator"
  chart     = "oci://harbor.regemini.io/helm/tarantool-operator"
  wait      = true
  atomic    = true
  namespace = local.namespace
  timeout   = 300
  version   = "1.0.1"
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
}


resource "helm_release" "tarantool_cartridge" {
  name      = "tarantool"
  chart     = "oci://harbor.regemini.io/helm/cartridge"
  wait      = true
  atomic    = true
  namespace = local.namespace
  timeout   = 300
  version   = "1.0.1"
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password

  values = [ file("${path.module}/cartridge-values.yaml") ]

  set{
    name = "tarantool.image.repository"
    value = "harbor.regemini.io/dev/tarantool"
  }
  set{
    name = "tarantool.image.tag"
    value = "v1.0.0"
  }
    set{
    name = "tarantool.auth.password"
    value = jsondecode(data.vault_generic_secret.cartridge_creds.data["credentials"]).password
  }
  set{
    name = "tarantool.roles[0].replicasets"
    value = local.storage_count
  }
  depends_on = [ 
    helm_release.tarantool_operator, 
    kubernetes_persistent_volume_claim.tarantool_router_pvc, 
    kubernetes_persistent_volume_claim.tarantool_storage_pvc 
  ]
}



