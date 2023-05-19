
resource "helm_release" "etcd" {
  name              = "etcd"
  chart             = "etcd"
  repository        = "https://harbor.regemini.io/chartrepo/op"
  version           = "6.10.8"
  namespace         = local.minioNs
  dependency_update = "true"
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password

  set {
    name  = "persistence.size"
    value = "1Gi"
  }
  set {
    name  = "auth.rbac.enabled"
    value = "false"
  }
  set {
    name  = "nodeSelector.workloadsType"
    value = "data"
  }
  set {
    name  = "tolerations[0].key"
    value = "workloadsType"
  }
  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }
  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }
  set {
    name  = "podAnnotations.sidecar\\.istio\\.io/inject"
    value = " false"
  }
  depends_on = [
    data.vault_generic_secret.harbor_token
  ]
}

data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}