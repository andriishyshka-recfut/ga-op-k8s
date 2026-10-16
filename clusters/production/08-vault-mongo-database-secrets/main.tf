module "vault_mongo_main_database_secrets" {
  source = "../../../terraform-modules/k8s-vault-mongo-database-secrets"

  providers = {
    kubernetes = kubernetes
    vault      = vault
  }

  Config               = local.mongodb_main_config
  ConnectionUrl        = local.mongodb_main_connection_url
  RootUsername         = data.vault_generic_secret.mongodb_main_admin.data["MONGODB_VAULT_CONNECTOR_USER"]
  RootPassword         = data.vault_generic_secret.mongodb_main_admin.data["MONGODB_VAULT_CONNECTOR_PASSWORD"]
  MongoHost            = local.mongodb_main_host
  MongoPort            = tonumber(local.mongodb_main_port)
  MongoReplicaSet      = local.mongodb_main_replica_set
  KubernetesNamespace  = "mongo"
  RoleReconcilerImage  = "percona/percona-server-mongodb:6.0.29-23"
  MountPath            = "mongodb"
  ConnectionName       = "production-mongo-main"
  PasswordPolicyName   = "main64"
  PolicyNamePrefix     = "production-mongodb"
  CustomRoleNamePrefix = local.mongodb_main_custom_role_name_prefix
}

module "vault_mongo_auth_database_secrets" {
  source = "../../../terraform-modules/k8s-vault-mongo-database-secrets"

  providers = {
    kubernetes = kubernetes
    vault      = vault
  }

  Config               = local.mongodb_auth_config
  ConnectionUrl        = local.mongodb_auth_connection_url
  RootUsername         = data.vault_generic_secret.mongodb_auth_admin.data["MONGODB_VAULT_CONNECTOR_USER"]
  RootPassword         = data.vault_generic_secret.mongodb_auth_admin.data["MONGODB_VAULT_CONNECTOR_PASSWORD"]
  MongoHost            = local.mongodb_auth_host
  MongoPort            = tonumber(local.mongodb_auth_port)
  MongoReplicaSet      = local.mongodb_auth_replica_set
  KubernetesNamespace  = "mongo-auth"
  RoleReconcilerImage  = "percona/percona-server-mongodb:6.0.29-23"
  MountPath            = "mongodb-auth"
  ConnectionName       = "production-mongo-auth"
  PasswordPolicyName   = "main64"
  PolicyNamePrefix     = "production-mongodb"
  CustomRoleNamePrefix = local.mongodb_auth_custom_role_name_prefix
}
