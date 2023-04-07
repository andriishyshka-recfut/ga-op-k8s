variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {

  namespaceNames = toset(flatten([
    for namespace in var.Settings.clusters[var.Cluster].namespaces : [namespace.name]
    if can(namespace.skipNsCreation) == false
  ]))


  injectHarborImagePullSecrets = toset(flatten([
    for namespace in var.Settings.clusters[var.Cluster].namespaces : [namespace.name] if lookup(namespace, "injectHarborImagePullSecrets", false)
  ]))

  injectApmSecrets = toset(flatten([
    for namespace in var.Settings.clusters[var.Cluster].namespaces : [namespace.name] if lookup(namespace, "injectApmCreds", false)
  ]))

  assignVaultPolicy = {
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name => namespace.assignVaultPolicy...
    if can(namespace.assignVaultPolicy)
  }

  minioCreds = {
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name => namespace.minioCreds...
    if can(namespace.minioCreds)
  }
  vaultUsersCredentialsPath = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/users"
}
