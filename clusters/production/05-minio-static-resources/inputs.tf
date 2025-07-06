locals {
  jsonIdentityData = jsondecode(file("${path.module}/identity.json"))
  jsonBucketsData  = jsondecode(file("${path.module}/buckets.json"))
  groupsMap        = lookup(local.jsonIdentityData, "groups", {})
  usersMap         = lookup(local.jsonIdentityData, "users", {})
  bucketsMap       = lookup(local.jsonBucketsData, "buckets", {})
  actionsMap       = merge(flatten([for group, data in local.groupsMap : [for bucket, actions in data : [for action in actions : { "${bucket}-${action}" = { "group" = group, "bucket" = bucket, "action" = action } }]]])...)
  usersGroups      = merge(flatten([for user, data in local.usersMap : [for type, names in data : [for name in names : { "${user}-${name}" = { "user" = user, "name" = name } } if type == "groups"]]])...)
  usersSa          = merge(flatten([for user, data in local.usersMap : [for type, names in data : [for name in names : { "${user}-${name}" = { "user" = user, "name" = name } } if type == "sa"]]])...)
  usersList        = toset(distinct(flatten([for users, data in local.usersMap : [for type, names in data : [for name in names : users]]])))
  bucketsIlm       = merge(flatten([for bucket, data in local.bucketsMap : [for rule, days in data : { "${bucket}-${rule}" = { "bucket" = bucket, "rule" = rule, "days" = days } }]])...)
}

data "vault_generic_secret" "minio_backup_user" {
  path = "secret/minio/root-helm"
}

data "vault_generic_secret" "minio_sa" {
  path = "secret/misc/sa/google/minio-sa"
}
