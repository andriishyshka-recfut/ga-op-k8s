
data "vault_generic_secret" "minio_auth" {
  path = "secret/minio/users"
}

data "vault_generic_secret" "harbor_passwords_secret" {
  path = "secret/harbor"
}

resource "helm_release" "harbor" {
  name       = "harbor"
  chart      = "harbor"
  repository = "https://helm.goharbor.io"
  wait       = true
  atomic     = true
  namespace  = "harbor"
  version    = local.harborVersion  
  timeout    = 900

  values = [
    file("${path.module}/harbor-values.yaml")
  ]

  set {
    name  = "harborAdminPassword"
    value = data.vault_generic_secret.harbor_passwords_secret.data.harborAdminPassword
  }

  set {
    name  = "database.internal.password"
    value = data.vault_generic_secret.harbor_passwords_secret.data.harborDatabasePassword
  }    

  set {
    name  = "database.external.password"
    value = data.vault_generic_secret.harbor_passwords_secret.data.harborDatabasePassword
  }   

  set {
    name  = "registry.credentials.username"
    value = data.vault_generic_secret.harbor_passwords_secret.data.harborRegistryUser
  }   

  set {
    name  = "registry.credentials.password"
    value = data.vault_generic_secret.harbor_passwords_secret.data.harborRegistryPassword
  }   

  set {
    name  = "persistence.imageChartStorage.s3.accesskey"
    value = jsondecode(data.vault_generic_secret.minio_auth.data.harbor).accessKey
  }

  set {
    name  = "persistence.imageChartStorage.s3.secretkey"
    value = jsondecode(data.vault_generic_secret.minio_auth.data.harbor).secretKey
  }
}