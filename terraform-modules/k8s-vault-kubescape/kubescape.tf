
data "vault_generic_secret" "minio_credentials" {
  path = "secret/mw/minio/sa/kubescape-reports_kubescape"
}


locals {
  accessKey               = data.vault_generic_secret.minio_credentials.data.ACCESS_KEY_ID
  secretKey               = data.vault_generic_secret.minio_credentials.data.SECRET_ACCESS_KEY
}



resource "helm_release" "kubescape" {
  name              = "kubescape"
  repository        = "${path.module}"
  chart             = "kubescape-operator"
  wait              = true
  atomic            = true
  namespace         = "kubescape"
  values = [templatefile("${path.module}/templates/values.tftpl",{values = local.values})]
  timeout = 60

}

