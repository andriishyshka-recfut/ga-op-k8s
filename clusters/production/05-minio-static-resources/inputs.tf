locals {
  jsonIdentityData = jsondecode(file("${path.module}/identity.json"))
  jsonBucketsData  = jsondecode(file("${path.module}/buckets.json"))
  groupsMap        = lookup(local.jsonIdentityData, "groups", {})
  usersMap         = lookup(local.jsonIdentityData, "users", {})
  bucketsMap       = lookup(local.jsonBucketsData, "buckets", {})
  policiesMap      = lookup(local.jsonIdentityData, "policies", {})
  # actionsMap       = merge(flatten([for group, data in local.groupsMap : [for bucket, actions in data : [for action in actions : { "${bucket}-${action}" = { "group" = group, "bucket" = bucket, "action" = action } }]]])...)
  groupPolicy   = merge([for group, policies in local.groupsMap : { for policy in policies : "${group}-${policy}" => { group = group, policy = policy } }]...)
  usersGroups   = merge(flatten([for user, data in local.usersMap : [for type, names in data : [for name in names : { "${user}-${name}" = { "user" = user, "name" = name } } if type == "groups"]]])...)
  usersSa       = merge(flatten([for user, data in local.usersMap : [for type, objects in data : [for object in objects : { "${user}-${object.name}" = merge(object, { "user" = user }) } if type == "sa"]]])...)
  usersList     = toset(distinct(flatten([for users, data in local.usersMap : [for type, names in data : [for name in names : users]]])))
  usersPolicies = merge(flatten([for user, data in local.usersMap : [for type, names in data : [for name in names : { "${user}-${name}" = { "user" = user, "name" = name } } if type == "policies"]]])...)
  bucketsIlm    = merge(flatten([for bucket, data in local.bucketsMap : [for rule, days in data : { "${bucket}-${rule}" = { "bucket" = bucket, "rule" = rule, "days" = days } }]])...)
  minioCa       = data.vault_generic_secret.minio_ca.data["certificate"]
  values = {
    groupsMap       = local.groupsMap
    usersMap        = local.usersMap
    bucketsMap      = local.bucketsMap
    policiesMap     = local.policiesMap
    groupPolicy     = local.groupPolicy
    usersGroups     = local.usersGroups
    usersSa         = local.usersSa
    usersList       = local.usersList
    usersPolicies   = local.usersPolicies
    bucketsIlm      = local.bucketsIlm
    minioCa         = local.minioCa
    minioSA         = "secret/misc/sa/google/minio-sa"
    minioBackupUser = "secret/mw/minio/root"
  }
}

data "vault_generic_secret" "minio_ca" {
  path = "pki-minio/cert/ca"
}
