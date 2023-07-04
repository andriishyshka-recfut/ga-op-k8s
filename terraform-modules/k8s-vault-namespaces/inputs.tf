variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  # [ "maid","magescanner", "crypto", ... ]
  # namespaceNames = toset(flatten([
  #   for namespace in var.Settings.clusters[var.Cluster].namespaces : [namespace.name]
  #   if can(namespace.skipNsCreation) == false
  # ]))

  namespaceNames = {
    for namespace in var.Settings.clusters[var.Cluster].namespaces : namespace.name => namespace
    if can(namespace.skipNsCreation) == false
  }

  #  {  crypto  = [[ "andrei.lavrenyuk@geminiadvisory.io",     ],] }
  namespaceAdmins = {
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name => namespace.admins...
    if can(namespace.admins)
  }
  developers = [
    "askat.abdikary@geminiadvisory.io",
    "vladyslav.martynenko@geminiadvisory.io",
    "anton@geminiadvisory.io",
    "eugene@geminiadvisory.io",
    "nikita.leonov@geminiadvisory.io",
    "valerii.korolov@geminiadvisory.io",
    "serhii.hutsaliuk@geminiadvisory.io",
    "mykhailo.kalashnikov@geminiadvisory.io",
    "oleh.babenko@geminiadvisory.io",
    "oleh.lialin@geminiadvisory.io",
    "oleksii.osinnii@geminiadvisory.io",
    "yehor.dudukin@geminiadvisory.io"
  ]
  namespaceDevAccess = toset(flatten([
    for namespace in var.Settings.clusters[var.Cluster].namespaces : [
      namespace.name
    ] if can(namespace.devAccess)
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

  devAccessAllowed      = var.Cluster == "production" ? 0 : 1
  appSpecificVaultRoles = var.Color == "red" ? 0 : 1
}
