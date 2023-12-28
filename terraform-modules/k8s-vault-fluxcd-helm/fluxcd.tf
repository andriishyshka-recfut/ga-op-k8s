data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "helm_release" "fluxcd" {
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  name       = "flux2"
  namespace  = local.namespace
}

resource "helm_release" "flux-crds" {
  name      = "flux-crds"
  namespace = local.namespace
  chart     = "oci://harbor.regemini.io/helm/flux-crds"
  wait      = true
  atomic    = true
  version             = "0.1.0"
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
  set {
    name  = "git_branch"
    value = var.Cluster
  }
  set {
    name  = "kustomization_path"
    value = "${var.Cluster}-${var.Color}"
  }
  set {
    name  = "slack_chanel"
    value = "fluxcd-${var.Cluster}"
  }
  set {
    name  = "web_password"
    value = bcrypt(random_password.flux_weave_gui.result)
  }
  depends_on = [helm_release.fluxcd, vault_generic_secret.flux_pass]
}

