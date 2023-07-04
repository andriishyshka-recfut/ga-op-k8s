locals {
  sftp_url   = "https://sftp.t.regemini.io"
  minio_user = "backup" #"sftpgo"
  bucket     = "minio-sftpgo-test" #"minio-sftpgo-orbital-wording"
  minio_endpoint = "https://minio.t.regemini.io/" #"https://minio.p.regemini.io/"
  minio_key_prefix = "clients/%username%/"
  clients    = nonsensitive(toset(data.vault_kv_secrets_list_v2.sftp_server_clients.names))
  all_sftp_users = toset([for name in local.clients: name if "${try(data.vault_generic_secret.client_secret["${name}"].data["sftp"], "false")}" == "true"])
  regemini_sftp_users = toset([for name in local.all_sftp_users: name if "${try(data.vault_generic_secret.client_secret["${name}"].data["sftpusername"], "")}" != ""])
}
