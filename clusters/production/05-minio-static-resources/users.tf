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

# resource "minio_iam_policy" "deny_all_user_policy" {
#   for_each = local.usersList
#   name     = each.key
#   policy   = <<EOF
# {
#   "Version":"2012-10-17",
#   "Statement": [
#     {
#       "Sid":"DenyAll",
#       "Effect": "Deny",
#       "Action": [
#         "s3:DeleteBucket",
#         "s3:CreateBucket"
#       ],
#       "Principal":"*",
#       "Resource": "arn:aws:s3:::*"
#     }
#   ]
# }
# EOF
# }

# resource "minio_iam_user_policy_attachment" "deny_all_user_policy" {
#   for_each    = local.usersList
#   user_name   = each.key
#   policy_name = minio_iam_policy.deny_all_user_policy[each.key].id
# }

resource "minio_iam_group_user_attachment" "group_user_attachment" {
  for_each   = local.usersGroups
  group_name = each.value.name
  user_name  = each.value.user
  depends_on = [
    minio_iam_user.users,
    minio_iam_policy.action_policy
  ]
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
  data_json = jsonencode(
    {
      access_key = "${minio_iam_service_account.service_account[each.key].access_key}"
      secret_key = "${minio_iam_service_account.service_account[each.key].secret_key}"
    }
  )
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
