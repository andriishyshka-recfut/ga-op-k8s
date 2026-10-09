data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

data "vault_generic_secret" "cartridge_creds" {
  path = "secret/vortex/cartridge"
}



resource "helm_release" "tarantool_operator" {
  name                = "tarantool-operator"
  chart               = "oci://harbor.regemini.io/helm/tarantool-operator"
  wait                = true
  atomic              = true
  namespace           = local.namespace
  timeout             = 300
  version             = local.operatorChartVersion
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
}


resource "helm_release" "tarantool_cartridge" {
  name                = "tarantool"
  chart               = "oci://harbor.regemini.io/helm/cartridge"
  wait                = true
  atomic              = true
  force_update        = true
  namespace           = local.namespace
  timeout             = 300
  version             = local.cartridgeChartVersion
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password

  values = [file("${path.module}/cartridge-values.yaml")]

  set  = [
    {
      name  = "tarantool.image.repository"
      value = "harbor.regemini.io/dev/tarantool"
    },
    {
      name  = "tarantool.image.tag"
      value = local.cartridgeTag
    },
    {
      name  = "tarantool.auth.password"
      value = jsondecode(data.vault_generic_secret.cartridge_creds.data["credentials"]).password
    },
    {
      name  = "tarantool.roles[0].replicasets"
      value = local.tsc
    },
    {
      name  = "tarantool.roles[0].persistence.spec.resources.requests.storage"
      value = "20Gi"
    },
    {
      name  = "tarantool.roles[0].resources.requests.cpu"
      value = local.storage_request_cpu
    },
    {
      name  = "tarantool.roles[0].resources.requests.memory"
      value = local.storage_request_mem
    },
    {
      name  = "tarantool.roles[0].resources.limits.cpu"
      value = local.storage_limit_cpu
    },
    {
      name  = "tarantool.roles[0].resources.limits.memory"
      value = local.storage_limit_mem
    },
    {
      name  = "tarantool.roles[0].memtxMemory"
      value = local.storage_memtx_memory
    },
    {
      name  = "tarantool.failover.etcd2.password"
      value = data.vault_generic_secret.etcd_creds.data.password
    }
  ]
  depends_on = [
    helm_release.tarantool_operator,
    helm_release.etcd,
    kubernetes_persistent_volume_claim.tarantool_router_pvc,
    kubernetes_persistent_volume_claim.tarantool_storage_pvc
  ]
}



