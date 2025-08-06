resource "minio_iam_group" "groups" {
  for_each = local.groupsMap
  name     = each.key
}

resource "minio_iam_policy" "action_policy" {
  for_each = local.policiesMap
  name     = each.key
  policy   = templatefile("${path.module}/../../../templates/minio/policy.tftpl", { values = each.value })
}

resource "minio_iam_group_policy_attachment" "action_attachment" {
  for_each    = local.groupPolicy
  group_name  = each.value.group
  policy_name = each.value.policy
  depends_on = [
    minio_iam_group.groups
  ]
}
