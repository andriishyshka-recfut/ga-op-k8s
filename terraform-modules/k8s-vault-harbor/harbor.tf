
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
    templatefile("${path.module}/templates/harbor-values.yaml.tftpl",{values = local.harborValues})
  ]

}