data "vault_generic_secret" "gitlab" {
  path = "secret/gitlab"
}

resource "kubernetes_secret" "gitlab-runner-registration" {
  for_each = var.gitlab_list
  metadata {
    name      = "gitlab-runner-registration"
    namespace = lookup(each.value, "namespace", local.namespace)
  }
  data = {
    runner-registration-token = data.vault_generic_secret.gitlab.data["runner_registration_token"]
  }
  depends_on = [
    data.vault_generic_secret.gitlab
  ]
}

# resource "kubernetes_secret" "minio" {
#   metadata {
#     name      = "minio"
#     namespace = "gitlab"
#   }
#   data = {
#     accesskey = data.vault_generic_secret.gitlab.data["minio_cache_accesskey"]
#     secretkey = data.vault_generic_secret.gitlab.data["minio_cache_secretkey"]
#   }
#   depends_on = [
#     data.vault_generic_secret.gitlab
#   ]
# }

data "kubernetes_secret" "gitlab-runner-registration" {
  for_each = var.gitlab_list
  metadata {
    name      = "gitlab-runner-registration"
    namespace = lookup(each.value, "namespace", local.namespace)
  }
  depends_on = [
    kubernetes_secret.gitlab-runner-registration
  ]
}

resource "helm_release" "gitlab-runner" {
  for_each   = var.gitlab_list
  name       = "gitlab-runner-${each.key}"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"
  wait       = true
  # force_update = true
  atomic     = true
  namespace  = lookup(each.value, "namespace", local.namespace)
  version    = each.value.runner_version
  values = [
    templatefile("${path.module}/runner-values.yaml.tftpl", merge({ values = each.value }, { name = each.key }))
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
    value = data.kubernetes_secret.gitlab-runner-registration[each.key].data["runner-registration-token"]
    type  = "string"
  }
  set {
    name  = "rbac.create"
    value = true
    type  = "string"
  }
}