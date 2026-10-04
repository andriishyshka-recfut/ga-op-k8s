resource "kubectl_manifest" "gitlab_secretstore" {
  yaml_body = templatefile("${path.module}/../../templates/external-secrets/SecretStore.tftpl",
    { values = { namespace = "flux-system", cluster = var.Cluster, color = var.Color, vault_url = local.vault_url } }
  )
}
# remove after full migration to github
resource "kubectl_manifest" "gitlab_secret" {
  yaml_body = templatefile("${path.module}/../../templates/external-secrets/ExternalSecret.tftpl",
    { values = { namespace = "flux-system", name = "gitlab-token", secret_name = "gitlab-token", vault_path = "misc/gitlab/token/read_repo", template_data = local.gitlab_secret_template } }
  )
}
#------------------------------------
resource "kubectl_manifest" "github_secret" {
  yaml_body = templatefile("${path.module}/../../templates/external-secrets/ExternalSecret.tftpl",
    { values = { namespace = "flux-system", name = "github-token", secret_name = "github-token", vault_path = "misc/github/app/recfut-gemini-fluxcd" } }
  )
}

