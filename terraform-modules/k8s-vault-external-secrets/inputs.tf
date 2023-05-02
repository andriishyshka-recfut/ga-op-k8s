variable "Cluster" {}
variable "Color" {}

locals {
  namespaces = ["camel-k", "magescanner", "sftp-jobs"]
  # namespaces = ["camel-k"]
}
