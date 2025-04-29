variable "Cluster" {}
variable "Color" {}
variable "Values" {}
variable "k8s" {}

locals {
  namespace = "flux-system"
  globals = {
    gitlab_token     = "gitlab-token",
    helm_credentials = "helm-credentials",
    namespace        = "flux-system"
  }
  git-repositories       = lookup(var.Values, "git-repositories", {})
  helm-repositories      = lookup(var.Values, "helm-repositories", {})
  helm-releases          = lookup(var.Values, "helm-releases", {})
  kustomizations         = lookup(var.Values, "kustomizations", {})
  notification-providers = lookup(var.Values, "notification-providers", {})
  alerts                 = lookup(var.Values, "alerts", {})
}


