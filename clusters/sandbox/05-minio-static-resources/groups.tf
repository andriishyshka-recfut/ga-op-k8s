resource "minio_iam_group" "groups" {
  for_each = local.groupsMap
  name     = each.key
}

locals {
  policy_list = merge(flatten([for group, data in local.groupsMap : { "${group}" = flatten([for bucket, actions in data : [for action in actions : 
jsonencode(
    {  
      "Sid" : "${bucket}-${action}",
      "Effect" : "Allow",
      "Principal" : "*",
      "Action" : ["s3:${action}"],
      "Resource" : "arn:aws:s3:::${bucket}*/*"
})
]])
}])...)
}


resource "minio_iam_policy" "group_policy" {
  for_each = local.policy_list
  name     = "${each.key}"
  policy= <<EOT
{"Version":"2012-10-17",
"Statement": [
${join(",", local.policy_list[each.key])},
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
]}
EOT
}

resource "minio_iam_group_policy_attachment" "group_policy_attachment" {
  for_each    = local.policy_list
  group_name  = each.key
  policy_name = minio_iam_policy.group_policy[each.key].id
  depends_on = [
    minio_iam_group.groups,
    minio_iam_policy.group_policy
  ]    
}

resource "minio_iam_group_policy_attachment" "consoleAdmin_attachment" {
  group_name  = "op"
  policy_name = "consoleAdmin"
  depends_on = [
    minio_iam_group.groups
  ]
}