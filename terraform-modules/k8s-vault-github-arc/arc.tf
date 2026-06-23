data "vault_generic_secret" "arc_tokens" {
  path = "secret/${local.vault_path}"
}

resource "kubernetes_secret" "arc" {
  metadata {
    name      = "arc-credentials"
    namespace = local.namespace
  }

  data = {
    github_app_id              = data.vault_generic_secret.arc_tokens.data.app_id
    github_app_installation_id = data.vault_generic_secret.arc_tokens.data.installation_id
    github_app_private_key     = data.vault_generic_secret.arc_tokens.data.private_key
  }
}

resource "helm_release" "github_arc_controller" {
  name       = "githun-arc-controller"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = var.Settings.clusters.production.versions.github-runner.helm_version_controller
  namespace  = local.namespace
  wait       = true
  atomic     = true
  timeout    = 300
  set = [
  {
    name  = "nodeSelector.workloadsType"
    value = "github-runners"
  },
  {
    name  = "tolerations[0].key"
    value = "workloadsType"
  },
  {
    name  = "tolerations[0].operator"
    value = "Equal"
  },
  {
    name  = "tolerations[0].value"
    value = "github-runners"
  },
  {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }
]
}

resource "helm_release" "github_arc" {
  name       = "github-arc"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = var.Settings.clusters.production.versions.github-runner.helm_version
  namespace  = local.namespace
  wait       = true
  atomic     = true
  timeout    = 300
  values = [templatefile("${path.module}/templates/values.tftpl",{values = {githubConfigSecret = kubernetes_secret.arc.metadata[0].name}})]

  depends_on = [
    kubernetes_secret.arc,
    helm_release.github_arc_controller
  ]
}
