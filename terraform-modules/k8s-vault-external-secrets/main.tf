data "vault_kv_secret_v2" "artifactory_creds" {
  mount = "secret"
  name  = "misc/artifactory/creds"
}

resource "helm_release" "external_secrets" {
  name                 = "external-secrets"
  chart                = "external-secrets"
  repository           = "oci://${var.RepositoryDomain}/ga-helm-virtual/external-secrets/charts"
  namespace            = "external-secrets"
  wait                 = true
  atomic               = true
  version              = var.Settings.clusters[var.Cluster].versions.external-secrets.helm_version
  repository_username  = data.vault_kv_secret_v2.artifactory_creds.data["user"]
  repository_password  = data.vault_kv_secret_v2.artifactory_creds.data["password"]
  repository_cert_file = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.crt" : null
  repository_key_file  = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.key" : null

  # dependency_update = "true"
  values = [
    file("${path.module}/values.yaml")
  ]
}


resource "time_sleep" "wait_180_seconds" {
  create_duration = "180s"
  depends_on      = [helm_release.external_secrets]
}

resource "kubectl_manifest" "external_secrets_store" {
  for_each   = toset(var.Color == "red" ? local.red_namespaces : local.namespaces)
  yaml_body  = templatefile("${path.module}/../../templates/external-secrets/SecretStore.tftpl", { values = { namespace = each.key, cluster = var.Cluster, color = var.Color } })
  depends_on = [time_sleep.wait_180_seconds]
}



