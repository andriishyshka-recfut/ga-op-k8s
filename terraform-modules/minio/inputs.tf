variable "Cluster" {}
variable "Color" {}
variable "Values" {}


locals {
  groupsMap     = var.Values.groupsMap
  usersMap      = var.Values.usersMap
  bucketsMap    = var.Values.bucketsMap
  policiesMap   = var.Values.policiesMap
  groupPolicy   = var.Values.groupPolicy
  usersGroups   = var.Values.usersGroups
  usersSa       = var.Values.usersSa
  usersList     = var.Values.usersList
  usersPolicies = var.Values.usersPolicies
  bucketsIlm    = var.Values.bucketsIlm
  minioCa       = var.Values.minioCa

}



data "vault_generic_secret" "minio_backup_user" {
  path = var.Values.minioBackupUser
}

data "vault_generic_secret" "minio_sa" {
  path = var.Values.minioSA
}
