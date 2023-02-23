resource "kubernetes_namespace" "gitlab" {
  metadata {
    name = "gitlab"
  }
}

data "vault_generic_secret" "gitlab" {
  path = "secret/gitlab"
  depends_on = [
    kubernetes_namespace.gitlab
  ]
}

resource "kubernetes_secret" "gitlab-runner-registration" {
  metadata {
    name      = "gitlab-runner-registration"
    namespace = "gitlab"
  }
  data = {
    runner-registration-token = data.vault_generic_secret.gitlab.data["runner_registration_token"]
  }
  depends_on = [
    data.vault_generic_secret.gitlab
  ]
}

resource "kubernetes_secret" "minio" {
  metadata {
    name      = "minio"
    namespace = "gitlab"
  }
  data = {
    accesskey = data.vault_generic_secret.gitlab.data["minio_cache_accesskey"]
    secretkey = data.vault_generic_secret.gitlab.data["minio_cache_secretkey"]
  }
  depends_on = [
    data.vault_generic_secret.gitlab
  ]
}

data "kubernetes_secret" "gitlab-runner-registration" {
  metadata {
    name      = "gitlab-runner-registration"
    namespace = "gitlab"
  }
  depends_on = [
    kubernetes_secret.gitlab-runner-registration
  ]
}

resource "helm_release" "gitlab-runner" {
  name       = "gitlab-runner"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"
  wait       = true
  atomic     = true
  namespace  = "gitlab"
  version    = "0.50.1"
  values = [
    file("${path.module}/runner-values.yaml")
  ]
  depends_on = [
    data.kubernetes_secret.gitlab-runner-registration
  ]
  set {
    name  = "gitlabUrl"
    value = "https://gitlab.regemini.com/"
    type  = "string"
  }
  set {
    name  = "runnerRegistrationToken"
    value = data.kubernetes_secret.gitlab-runner-registration.data["runner-registration-token"]
    type  = "string"
  }
  set {
    name  = "rbac.create"
    value = true
    type  = "string"
  }
}

