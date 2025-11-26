resource "minio_iam_group" "groups" {
  for_each = local.groupsMap
  name     = each.key
}

resource "random_id" "policy_id" {
  for_each = local.policiesMap
  byte_length = 16
}


resource "minio_iam_policy" "action_policy" {
  for_each = local.policiesMap
  name     = each.key
  policy   = templatefile("${path.module}/../../templates/minio/policy.tftpl", { values = each.value, uuid = random_id.policy_id[each.key].hex})
  depends_on = [ random_id.policy_id ]
}

resource "minio_iam_group_policy_attachment" "action_attachment" {
  for_each    = local.groupPolicy
  group_name  = each.value.group
  policy_name = each.value.policy
  depends_on = [ minio_iam_group.groups ]
}
