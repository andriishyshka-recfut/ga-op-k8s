module "vault_mongo_database_secrets" {
  source = "../../../terraform-modules/k8s-vault-mongo-database-secrets"

  providers = {
    kubernetes = kubernetes
    vault      = vault
  }

  Config               = local.config
  ConnectionUrl        = local.mongodb_connection_url
  RootUsername         = data.vault_generic_secret.mongodb_admin.data["MONGODB_VAULT_CONNECTOR_USER"]
  RootPassword         = data.vault_generic_secret.mongodb_admin.data["MONGODB_VAULT_CONNECTOR_PASSWORD"]
  MongoHost            = local.mongodb_host
  MongoPort            = tonumber(local.mongodb_port)
  MongoReplicaSet      = local.mongodb_replica_set
  KubernetesNamespace  = "mongo"
  RoleReconcilerImage  = "percona/percona-server-mongodb:6.0.29-23"
  MountPath            = "mongodb"
  ConnectionName       = "sandbox-mongo-main"
  PasswordPolicyName   = "main64"
  PolicyNamePrefix     = "sandbox-mongodb"
  CustomRoleNamePrefix = local.mongodb_custom_role_name_prefix
}
