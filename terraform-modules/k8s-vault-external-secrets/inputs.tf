variable "Cluster" {}
variable "Color" {}

locals {
  namespaces = var.Cluster == "production" ? ["camel-k", "magescanner"] : ["magescanner"]
  # namespaces = ["camel-k"]
}
