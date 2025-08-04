data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "helm_release" "fluxcd" {
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  name       = "flux2"
  version    = var.Settings.clusters[var.Cluster].versions.fluxcd.helm_version
  namespace  = local.namespace
  values = [
    file("${path.module}/flux-values.yaml")
  ]
}





