resource "vault_kv_secret_v2" "user_secret" {
  for_each            = local.usersList
  mount               = "secret"
  name                = "mw/minio/users/${each.key}"
  delete_all_versions = true
  data_json = jsonencode(
    {
      accessKey = each.key,
      secretKey = "${minio_iam_user.users[each.key].secret}"
    }
  )
  custom_metadata {
    max_versions = 5
    data = {
      name = each.key
    }
  }
}

resource "minio_iam_user" "users" {
  for_each      = local.usersList
  name          = each.key
  force_destroy = false
  tags = {
    tag-key = each.key
  }
}

resource "minio_iam_group_user_attachment" "group_user_attachment" {
  for_each   = local.usersGroups
  group_name = each.value.name
  user_name  = each.value.user
  depends_on = [
    minio_iam_user.users
  ]
}

resource "minio_iam_user_policy_attachment" "user_policy_attachment" {
  for_each    = local.usersPolicies
  user_name   = each.value.user
  policy_name = each.value.name
  depends_on = [ minio_iam_user.users ]
}

resource "minio_iam_service_account" "service_account" {
  for_each    = local.usersSa
  name        = "${each.value.name}-${each.value.user}"
  target_user = each.value.user
  depends_on = [
    minio_iam_user.users
  ]
}
resource "vault_kv_secret_v2" "sa_secret" {
  for_each            = local.usersSa
  mount               = "secret"
  name                = "mw/minio/sa/${each.value.name}_${each.value.user}"
  delete_all_versions = true
  data_json = templatefile("${path.module}/../../templates/minio/vault_sa_secret.tftpl", {
    creds  = minio_iam_service_account.service_account[each.key],
    ca_crt = local.minioCa,
    values = each.value
  })
  custom_metadata {
    max_versions = 5
    data = {
      name = each.key
    }
  }
  depends_on = [
    minio_iam_service_account.service_account
  ]
}
