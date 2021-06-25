#
# data "google_service_account" "vault_sa" {
#   account_id = "vault-sandbox"
# }
#
# resource "google_service_account_key" "harbor_key" {
#   service_account_id = data.google_service_account.vault_sa.name
# }
#


data "vault_generic_secret" "minio_auth" {
  path = "secret/minio/users"
}

resource "helm_release" "harbor" {
  name       = "harbor"
  chart      = "harbor"
  repository = "https://helm.goharbor.io"
  wait       = true
  atomic     = true
  namespace  = "harbor"
  version    = "v1.7.0"
  timeout    = 900

  values = [
    file("${path.module}/harbor-values.yaml")
  ]

  set {
    name  = "persistence.imageChartStorage.s3.accesskey"
    value = jsondecode(data.vault_generic_secret.minio_auth.data.harbor).accessKey
  }

  set {
    name  = "persistence.imageChartStorage.s3.secretkey"
    value = jsondecode(data.vault_generic_secret.minio_auth.data.harbor).secretKey
  }
}
