variable "Cluster" {}
variable "Settings" {}
variable "Color" {}

locals {
  vault_path = "misc/github/token"
  namespace = "github"
}
