resource "minio_iam_group" "groups" {
  for_each = local.groupsMap
  name     = each.key
}

resource "minio_iam_policy" "action_policy" {
  for_each = local.actionsMap
  name     = "${each.value.bucket}-${each.value.action == "*" ? "rw" : lower(each.value.action)}"
  policy   = <<EOF
{
  "Version":"2012-10-17",
  "Statement": [
    {
      "Sid":"${each.value.action == "*" ? "RW" : each.value.action}",
      "Effect": "Allow",
      "Action": ["s3:${each.value.action}"],
      "Principal":"*",
      "Resource": "arn:aws:s3:::${each.value.bucket}*/*"
    }
  ]
}
EOF
}

resource "minio_iam_group_policy_attachment" "action_attachment" {
  for_each    = local.actionsMap
  group_name  = each.value.group
  policy_name = minio_iam_policy.action_policy[each.key].id
  depends_on = [
    minio_iam_group.groups
  ]    
}

resource "minio_iam_group_policy_attachment" "consoleAdmin_attachment" {
  group_name  = "op"
  policy_name = "consoleAdmin"
  depends_on = [
    minio_iam_group.groups
  ]    
}


resource "minio_iam_policy" "deny_all_action_policy" {
  name   = "DenyAll"
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement": [
    {
      "Sid":"DenyAll",
      "Effect": "Deny",
      "Action": [
        "s3:DeleteBucket",
        "s3:CreateBucket"
      ],
      "Principal":"*",
      "Resource": "arn:aws:s3:::*"
    }
  ]
}
EOF
}

resource "minio_iam_group_policy_attachment" "deny_all_action_attachment" {
  for_each    = local.groupsMap
  group_name  = each.key
  policy_name = minio_iam_policy.deny_all_action_policy.id
  depends_on = [
    minio_iam_group.groups
  ]    
}