data "vault_generic_secret" "gitlab_token" {
  path = "secret/gitlab"
}

resource "kubernetes_secret" "gitlab-token" {
  metadata {
    name      = "gitlab-token"
    namespace = local.ns
  }

  data = {
    "username" = data.vault_generic_secret.gitlab_token.data.username
    "password" = data.vault_generic_secret.gitlab_token.data.fluxcd
  }
  depends_on = [kubernetes_namespace.ns]

}


resource "helm_release" "fluxcd" {
  name = "fluxcd"

  chart      = "flux"
  repository = "https://charts.fluxcd.io"
  #version           = "0.1.0"
  namespace         = local.ns
  dependency_update = "true"

  set {
     name = "git.url"
     value = "https://$(username):$(password)@gitlab.regemini.com/op/sandbox.git"
    }
  set {
    name="env.secretName"
    value="gitlab-token"
  }
  set {
    name="git.branch"
    value="kubernetes"
  }
  set {
    name="git.path"
    value="crypto-ns/"
    }
  set {
    name="allowedNamespaces[0]"
    value=local.ns
    }
  set {
    name="registry.automationInterval"
    value="1m"
    }
  set {
    name="git.pollInterval"
    value="1m"
    }
  set {
    name="git.ciSkip"
    value=true
  }

  depends_on = [
    kubernetes_secret.gitlab-token,

  ]
}
