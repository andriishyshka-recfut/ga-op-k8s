resource "kubernetes_default_service_account_v1" "default" {
  for_each = local.repoSecretNamespaces

  metadata {
    namespace = each.key
  }

  dynamic "image_pull_secret" {
    for_each = toset(local.enabled_repo_secrets)

    content {
      name = image_pull_secret.value
    }
  }
}