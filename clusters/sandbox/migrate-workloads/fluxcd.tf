
data "vault_generic_secret" "gitlab_token" {
  path = "secret/gitlab"
}

resource "kubernetes_secret" "gitlab_token" {
  metadata {
    name      = "gitlab-token"
    namespace = "fluxcd"
  }

  data = {
    "username" = data.vault_generic_secret.gitlab_token.data.username
    "password" = data.vault_generic_secret.gitlab_token.data.fluxcd
  }

}


resource "helm_release" "fluxcd" {
  name = "fluxcd"

  chart      = "flux"
  repository = "https://charts.fluxcd.io"
  #version           = "0.1.0"
  namespace         = "fluxcd"
  dependency_update = "true"

  set {
    name  = "git.url"
    value = "https://$(username):$(password)@gitlab.regemini.com/op/k8s.git"
  }
  set {
    name  = "env.secretName"
    value = "gitlab-token"
  }
  set {
    name  = "git.branch"
    value = "core-kustomize"
  }
  set {
    name  = "git.path"
    value = "app-configs/core/sandbox/"
  }
  set {
    name  = "allowedNamespaces[0]"
    value = "core"
  }
  set {
    name  = "registry.automationInterval"
    value = "1m"
  }
  set {
    name  = "git.pollInterval"
    value = "1m"
  }
  set {
    name  = "git.ciSkip"
    value = true
  }
  set {
    name  = "manifestGeneration"
    value = "true"
  }

  depends_on = [
    kubernetes_secret.gitlab_token,
    module.namespaces,
    module.data-elastic

  ]
}
