data "vault_kv_secret_v2" "artifactory_creds" {
  mount = "secret"
  name  = "misc/artifactory/creds"
}
resource "helm_release" "thanos" {
  name              = "thanos"
  chart             = "thanos"
#  repository        = "https://charts.bitnami.com/bitnami"
#  repository        = "oci://registry-1.docker.io/bitnamicharts"
#  waiting to resync 
  repository        = "oci://${var.artifactoryRepoDomain}/ga-helm-virtual/bitnamicharts"
  wait              = true
  timeout           = 900
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
  version           = local.helmVersion
  take_ownership    = false
  upgrade_install   = false
  repository_username = data.vault_kv_secret_v2.artifactory_creds.data["user"]
  repository_password = data.vault_kv_secret_v2.artifactory_creds.data["password"]
  repository_cert_file = var.artifactoryRepoDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.crt" : null
  repository_key_file  = var.artifactoryRepoDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.key" : null
  values = [
    templatefile("${path.module}/${local.thanosConfigFile}", {
      additional_rule_labels             = var.Cluster,
      thanos_version                     = local.thanosVersion
    })
  ]
}
