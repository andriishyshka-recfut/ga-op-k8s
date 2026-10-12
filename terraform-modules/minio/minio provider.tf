terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
    }
  }
}

provider "minio" {
  minio_server   = var.Cluster == "production" ? (var.Color == "red" ? "minio-api-red.p.regemini.io:443" : "minio-helm-api.p.regemini.io:443") : "minio-helm-api.t.regemini.io:443"
  minio_user     = data.vault_generic_secret.minio_backup_user.data.accessKey
  minio_password = data.vault_generic_secret.minio_backup_user.data.secretKey
  minio_ssl      = true
}
