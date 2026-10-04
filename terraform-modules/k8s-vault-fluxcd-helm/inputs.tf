variable "Cluster" {}
variable "Color" {}
variable "Settings" {}

locals {
  namespace = "flux-system"
  # remove after full migration to github
  gitlab_secret_template = [
    { k8s_key = "username", vault_key = "username"},
    { k8s_key = "password", vault_key = "token"}
  ]
  helm_creds_template = [
      { k8s_key = "username", vault_key = "user" },
      { k8s_key = "password", vault_key = "password" }
  ]
  # ----------------------------------------
  artifactory_creds_template = [
    { k8s_key = "username", vault_key = "user" },
    { k8s_key = "password", vault_key = "password" }
  ]
  artifactory_mtls_template = [
    { k8s_key = "tls.crt", vault_key = "tls_crt" },
    { k8s_key = "tls.key", vault_key = "tls_key" }
  ]
  vault_url = var.Cluster == "production" ? "https://vault.p.regemini.io" : "https://vault.t.regemini.io"
  vault_slack_key = var.Cluster == "production" ? "gemini_fluxcd-live" : "gemini_fluxcd-test"
}

