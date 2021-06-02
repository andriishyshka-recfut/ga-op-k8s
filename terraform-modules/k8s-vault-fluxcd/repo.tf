
data "vault_generic_secret" "gitlab_token" {
  path = "secret/gitlab"
}

resource "kubernetes_secret" "gitlab_token" {
  metadata {
    name      = "gitlab-token"
    namespace = data.flux_install.main.namespace
  }

  data = {
    "username" = data.vault_generic_secret.gitlab_token.data.username
    "password" = data.vault_generic_secret.gitlab_token.data.fluxcd
  }
  depends_on = [kubectl_manifest.install]
}

locals{
  helmRepo = file("${path.module}/helm-repository.yaml")
  repo = replace (
         file("${path.module}/git-repository.yaml"),
         "CHANGEME",
         var.Cluster
  )
  kustomization = replace(
                  file("${path.module}/kustomization.yaml"),
                  "CHANGEME",
                  "${var.Cluster}-${var.Color}"
                  )

}
resource "kubectl_manifest" "repo" {
  yaml_body  = local.repo
}
resource "kubectl_manifest" "helm_repo" {
  yaml_body  = local.helmRepo
}
resource "kubectl_manifest" "kustomization" {
  yaml_body  = local.kustomization
}
