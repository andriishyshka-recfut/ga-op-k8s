variable "Cluster" {}
variable "Color" {}
variable "Settings" {}

locals {
  namespace = "flux-system"
  gitlab_secret_template = [
    { k8s_key = "username", vault_key = "username"},
    { k8s_key = "password", vault_key = "token"}
  ]
  vault_url = var.Cluster == "production" ? "https://vault.p.regemini.io" : "https://vault.t.regemini.io"
  vault_slack_key = var.Cluster == "production" ? "gemini_fluxcd-live" : "gemini_fluxcd-test"
}

