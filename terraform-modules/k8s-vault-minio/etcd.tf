
resource "helm_release" "etcd" {
  name              = "etcd"
  chart             = "etcd"
  repository        = "oci://harbor.regemini.io/helm"
  version           = "6.10.8"
  namespace         = local.minioNs
  dependency_update = "true"
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password

  set = [
    {
      name = "image.tag"
      value = "3.5.16-debian-12-r4"
    },
    {
      name = "image.repository"
      value = "bitnamilegacy/etcd"
    },
    {
      name  = "persistence.size"
      value = "1Gi"
    },
    {
      name  = "auth.rbac.enabled"
      value = "false"
    },
    {
      name  = "nodeSelector.workloadsType"
      value = "data"
    },
    {
      name  = "tolerations[0].key"
      value = "workloadsType"
    },
    {
      name  = "tolerations[0].operator"
      value = "Exists"
    },
    {
      name  = "tolerations[0].effect"
      value = "NoSchedule"
    },
    {
      name  = "podAnnotations.sidecar\\.istio\\.io/inject"
      value = " false"
    },
    {
      name  = "resources.requests.cpu"
      value = "20m"
    },
    {
      name  = "resources.requests.memory"
      value = "64Mi"
    },
    {
      name  = "resources.limits.cpu"
      value = "100m"
    },
    {
      name  = "resources.limits.memory"
      value = "256Mi"
    }
  ]
  depends_on = [
    data.vault_generic_secret.harbor_token
  ]
}

data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}