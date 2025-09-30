variable "Cluster" {}
variable "Color" {}
variable "Settings" {}

locals {
  namespace = "flux-system"
  gitlab_secret_template = [
    { k8s_key = "username", vault_key = "username"},
    { k8s_key = "password", vault_key = "token"}
  ]
  vault_url = var.Color == "red" ? "https://vault.p.regemini.io" : "http://vault-active.vault:8200"   
}

