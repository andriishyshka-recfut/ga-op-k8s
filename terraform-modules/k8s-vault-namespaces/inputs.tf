
variable "Settings" {}
variable "Cluster" {}


locals {
  # [ "maid","magescanner", "crypto", ... ]
  namespaceNames = toset(flatten([
    for namespace in var.Settings.clusters[var.Cluster].namespaces : [namespace.name]
  ]))

  #  {  crypto  = [[ "andrei.lavrenyuk@geminiadvisory.io",     ],] }
  namespaceAdmins = {
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name => namespace.admins...
    if can(namespace.admins)
  }
  namespaceKubefwd = {
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name => namespace.kubefwdGroups...
    if can(namespace.kubefwdGroups)
  }

  injectHarborCreds = toset(flatten([
    for namespace in var.Settings.clusters[var.Cluster].namespaces : [namespace.name] if lookup(namespace, "injectHarborCreds", false)
  ]))

  assignVaultPolicy = {
    for namespace in var.Settings.clusters[var.Cluster].namespaces :
    namespace.name => namespace.assignVaultPolicy...
    if can(namespace.assignVaultPolicy)
  }
}
