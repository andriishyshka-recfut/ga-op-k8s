data "vault_generic_secret" "minio_creds" {
  path         = "secret/minio/users"
}


resource "sftpgo_group" "minio" {
  name = "minio"
  description = "Group with minio storage"
  user_settings = {
    filesystem = {
      provider = 1 #S3 compatible provider
      s3config = {
        bucket = local.bucket
        access_key = jsondecode(data.vault_generic_secret.minio_creds.data["${local.minio_user}"]).accessKey
        access_secret = jsondecode(data.vault_generic_secret.minio_creds.data["${local.minio_user}"]).secretKey
        endpoint = local.minio_endpoint
        force_path_style = true
        key_prefix = local.minio_key_prefix
      }
    }

  }
}

data "vault_kv_secrets_list_v2" "sftp_server_clients" {
  mount = "secret"
  name  = "etl/clients"
}

data "vault_generic_secret" "client_secret" {
  for_each = local.clients
  path         = "secret/etl/clients/${each.key}"
}

resource "sftpgo_user" "users" {
  for_each = nonsensitive(local.regemini_sftp_users)
  filesystem = {
    provider = 0
  }
  home_dir = "/tmp/${regex("^?-([0-9A-z]+)", "${each.key}")[0]}"
  permissions = {"/":"*"}
  status = data.vault_generic_secret.client_secret["${each.key}"].data["sftp"] == "true" ? 1 : 0
  groups = [
    {"name": "${sftpgo_group.minio.name}","type": 1 },
  ]
  public_keys = ["${nonsensitive(data.vault_generic_secret.client_secret["${each.key}"].data["sftp_pub_keys"])}"]
  username = "${regex("^?-([0-9A-z]+)", "${each.key}")[0]}"
  password = data.vault_generic_secret.client_secret["${each.key}"].data["sftp_password"]
  email    = try(data.vault_generic_secret.client_secret["${each.key}"].data["sftp_email"], "email-address-of-the-client@url-of-server.domain")
  description = try(data.vault_generic_secret.client_secret["${each.key}"].data["sftp_description"], "description")
  quota_size  = 734003200
  quota_files = 200
  upload_bandwidth = 1024
  filters = {
    password_strength = 16
    password_expiration = 180
  }
depends_on = [sftpgo_group.minio]
}