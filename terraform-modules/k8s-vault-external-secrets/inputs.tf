variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "RepositoryDomain" {}

locals {
  namespaces     = ["magescanner"]
  red_namespaces = []
}
