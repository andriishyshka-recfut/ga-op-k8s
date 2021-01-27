
resource "helm_release" "psmdb_operator" {
  name       = "psmdb-operator"
  chart      = "psmdb-operator"
  repository = "https://percona.github.io/percona-helm-charts/"
  wait       = true
  atomic     = true
  namespace  = local.mongoNs
  timeout    = 900
}

data "vault_generic_secret" "mongo_creds" {
  path = var.CredsPath
}


resource "kubernetes_secret" "mongo" {
  metadata {
    name      = "mongo"
    namespace = local.mongoNs
  }

  data = data.vault_generic_secret.mongo_creds.data

}

data "vault_generic_secret" "minio_backup_user" {
  path = "secret/minio/root"
}

resource "kubernetes_secret" "mongo_backup" {
  metadata {
    name      = "mongo-backup"
    namespace = local.mongoNs
  }

  data = {
    AWS_ACCESS_KEY_ID     = data.vault_generic_secret.minio_backup_user.data.accessKey
    AWS_SECRET_ACCESS_KEY = data.vault_generic_secret.minio_backup_user.data.secretKey
  }

}
resource "helm_release" "mongo_cluster" {
  name      = "mongo-cluster"
  chart     = "${path.module}/mongo"
  namespace = local.mongoNs
  wait      = true
  atomic    = true
  depends_on = [
    helm_release.psmdb_operator,
    kubernetes_secret.mongo,
    kubernetes_secret.mongo_backup
  ]
}
