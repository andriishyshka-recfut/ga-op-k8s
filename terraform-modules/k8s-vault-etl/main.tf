data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "helm_release" "etl_operator" {
  name                = "etl-operator"
  chart               = "oci://harbor.regemini.io/helm/etl-operator"
  version             = "0.1.3"
  namespace           = local.namespace
  wait                = true
  atomic              = true
  recreate_pods       = true
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
  set {
    name  = "image.tag"
    value = local.operatorTag
  }
  set {
    name  = "ansibleGit.tag"
    value = local.ansibleScriptsTag
  }
  set {
    name  = "camino.tag"
    value = local.caminoTag
  }
  set {
    name  = "gs2s3.tag"
    value = local.gs2s3Tag
  }
  set {
    name  = "vaultPath"
    value = "k8s-${var.Cluster}-${var.Color}"
  }
  set {
    name  = "vaultRole"
    value = local.namespace
  }
  set {
    name  = "monitoredNamespace"
    value = local.namespace
  }
  set {
    name  = "elasticSecretsPath"
    value = local.elasticSecretsPath
  }
  set {
    name  = "resources.requests.cpu"
    value = "200m"
  }
  set {
    name  = "resources.requests.memory"
    value = "512Mi"
  }
  set {
    name  = "resources.limits.cpu"
    value = "1200m"
  }
  set {
    name  = "resources.limits.memory"
    value = "768Mi"
  }
}
