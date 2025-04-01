terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "3.3.0"
    }
  }
}

provider "minio" {
  minio_server   = var.Cluster == "production" ? "minio-api.p.regemini.io:443" : "minio-api.t.regemini.io:443"
  minio_user     = data.vault_generic_secret.minio_backup_user.data.accessKey
  minio_password = data.vault_generic_secret.minio_backup_user.data.secretKey
  minio_ssl      = true
}

data "vault_generic_secret" "minio_backup_user" {
  path = "secret/minio/root"
}

data "vault_kv_secrets_list_v2" "minio_iam_user" {
  mount = "secret"
  name  = "mw/minio/iam"
}

locals {
  clients = nonsensitive(toset(data.vault_kv_secrets_list_v2.minio_iam_user.names))
}

data "vault_generic_secret" "minio_iam_user" {
  for_each = local.clients
  path     = "secret/mw/minio/iam/${each.key}"
}

resource "minio_iam_user" "user" {
  for_each      = local.clients
  name          = "${replace(each.key, "/@.*/", "")}_${data.vault_generic_secret.minio_iam_user[each.key].data.accessKey}"
  secret        = data.vault_generic_secret.minio_iam_user[each.key].data.secretKey
  force_destroy = true
  tags = {
    tag-key = each.key
  }
}

resource "minio_iam_policy" "user_policy" {
  for_each = local.clients
  name     = each.key
  policy   = data.vault_generic_secret.minio_iam_user[each.key].data.policy
}

resource "minio_iam_user_policy_attachment" "developer" {
  for_each = local.clients
  user_name   = minio_iam_user.user[each.key].id
  policy_name = minio_iam_policy.user_policy[each.key].id
}

# resource "minio_iam_service_account" "user_service_account" {
#   for_each    = { for key, client in local.clients: client => key if data.vault_generic_secret.minio_iam_user[key].data.serviceAccountNames }
#   target_user = minio_iam_user.user[each.key].name
#   policy   = data.vault_generic_secret.minio_iam_user[each.key].data.serviceAccountNames
# }
