variable "Cluster" {}
variable "Color" {}
variable "Values" {}

locals {
  namespace = "flux-system"
  globals = {
    gitlab_token     = "gitlab-token",
    github_token     = "github-token",
    helm_credentials = "helm-credentials",
    namespace        = "flux-system"
    provider         = "generic"
  }
  git-repositories       = lookup(var.Values, "git-repositories", {})
  helm-repositories      = lookup(var.Values, "helm-repositories", {})
  helm-releases          = lookup(var.Values, "helm-releases", {})
  kustomizations         = lookup(var.Values, "kustomizations", {})
  notification-providers = lookup(var.Values, "notification-providers", {})
  alerts                 = lookup(var.Values, "alerts", {})
}


