
data "vault_generic_secret" "minio_credentials" {
  path = "secret/minio/users"
}


locals {
  accessKey               = jsondecode(data.vault_generic_secret.minio_credentials.data["kubescape"]).accessKey
  secretKey               = jsondecode(data.vault_generic_secret.minio_credentials.data["kubescape"]).secretKey
}


resource "kubernetes_secret" "minio_credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = "kubescape"
  }

  data = {
    "accesskey" = local.accessKey
    "secretkey" = local.secretKey
  }
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

  depends_on = [kubernetes_secret.minio_credentials]
}

