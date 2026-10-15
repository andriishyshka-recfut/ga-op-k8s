variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


locals {
  # [ "maid","magescanner", "crypto", ... ]
  # namespaceNames = toset(flatten([
  #   for namespace in var.Settings.clusters[var.Cluster].namespaces : [namespace.name]
  #   if can(namespace.skipNsCreation) == false
  # ]))
  harborEnable      = true
  artifactoryEnable = true

  enabled_repo_secrets = compact([
    local.harborEnable ? "harbor" : null,
    local.artifactoryEnable ? "artifactory-creds" : null,
  ])


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
    "dev@geminiadvisory.io", "gke-security-groups-rf-dev@geminiadvisory.io"
  ]

  namespaceDevAccess = toset(flatten([
    for namespace in var.Settings.clusters[var.Cluster].namespaces : [
      namespace.name
    ] if can(namespace.devAccess)
  ]))

  repoSecretNamespaces = toset([
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name
    if lookup(namespace, "repoSecret", false)
  ])

  repoSecretServiceAccountsByNamespace = {
    for name, namespace in local.namespaceNames :
    name => try(namespace.repoSecretSA, "") != "" ? { "registry/service-accounts": join(",",namespace.repoSecretSA), "registry/image-pull-secrets": join(",",local.enabled_repo_secrets) } : null
    
  }

  injectHarborImagePullSecrets = toset([
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name
    if lookup(namespace, "repoSecret", false) && local.harborEnable
  ])

  injectArtifactoryImagePullSecrets = toset([
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name
    if lookup(namespace, "repoSecret", false) && local.artifactoryEnable
  ])

  injectHarborUserPassword = toset(flatten([
    for namespace in var.Settings.clusters[var.Cluster].namespaces : [namespace.name] if lookup(namespace, "harborUserPassword", false)
  ]))

  assignVaultPolicy = {
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name => namespace.assignVaultPolicy...
    if can(namespace.assignVaultPolicy)
  }

  minioCreds = {
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name => namespace.minioCreds
    if can(namespace.minioCreds)
  }
  vaultUsersCredentialsPath = var.Settings.clusters[var.Cluster][var.Color].minio.vault_mng_users_config_path

  devAccessAllowed      = var.Cluster == "production" ? 0 : 1
  appSpecificVaultRoles = var.Color == "red" ? 0 : 1
}
