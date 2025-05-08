# data "vault_generic_secret" "users_from_old_vault" {
#   path = "secret/minio/users"
# }

# locals {
#   policy = tomap({ for user in nonsensitive(keys(data.vault_generic_secret.users_from_old_vault.data)) : user => nonsensitive(jsonencode(jsondecode(data.vault_generic_secret.users_from_old_vault.data[user]))) })
#   users = toset(nonsensitive(keys(jsondecode(data.vault_generic_secret.users_from_old_vault.data_json)))) 
# }

# # resource "vault_generic_secret" "vault_new_users" {  // DO NOT DESTROY!!! THIS WILL DELETE ALL MINIO USERS.
# #   for_each  = toset(local.users)
# #   path      = "secret/mw/minio/iam/${each.key}"
# #   data_json = local.policy[each.key]

# #   lifecycle {
# #     prevent_destroy = true
# #   }
# # }
