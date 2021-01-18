
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}


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
}
