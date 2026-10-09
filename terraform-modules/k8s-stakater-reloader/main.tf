data "vault_kv_secret_v2" "artifactory_creds" {
  mount = "secret"
  name  = "misc/artifactory/creds"
}

resource "helm_release" "stakater" {
  name       = "stakater"
  namespace  = local.namespace
  repository = "oci://${var.artifactoryRepoDomain}/ga-helm-virtual/stakater/charts"
  chart      = "reloader"
  wait       = true
  atomic     = true
  version    = local.chartVersion
  repository_username  = data.vault_kv_secret_v2.artifactory_creds.data["user"]
  repository_password  = data.vault_kv_secret_v2.artifactory_creds.data["password"]
  repository_cert_file = var.artifactoryRepoDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.crt" : null
  repository_key_file  = var.artifactoryRepoDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.key" : null
  values = [
    templatefile("${path.module}/stakater.tftpl", { artifactoryRepoDomain = var.artifactoryRepoDomain })
  ]
}
