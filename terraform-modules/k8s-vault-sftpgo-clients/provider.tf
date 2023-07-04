terraform {
  required_providers {
    sftpgo = {
      source  = "drakkan/sftpgo"
      version = "0.0.7"
    }
  }
}

data "vault_generic_secret" "sftp_admin" {
  path         = "secret/sftp-server/admin"
}

provider "sftpgo" {
  host     = var.sftp_url
  username = data.vault_generic_secret.sftp_admin.data["login"]
  password = data.vault_generic_secret.sftp_admin.data["password"]
}