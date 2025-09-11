terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      # version = "3.6.5"
    }
  }
}

provider "minio" {
  # minio_server   = var.Cluster == "production" ? "minio-helm-api.p.regemini.io:443" : "minio-helm-api.t.regemini.io:443"
  minio_server   = "minio-helm-api.p.regemini.io:443"
  minio_user     = data.vault_generic_secret.minio_backup_user.data.accessKey
  minio_password = data.vault_generic_secret.minio_backup_user.data.secretKey
  minio_ssl      = true
}
