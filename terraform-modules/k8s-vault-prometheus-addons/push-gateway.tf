data "vault_kv_secret_v2" "artifactory_creds" {
  mount = "secret"
  name  = "misc/artifactory/creds"
}
resource "helm_release" "pushgateway" {
  name              = "pushgateway"
  repository        = "oci://${var.artifactoryRepoDomain}/ga-helm-virtual/prometheus-community/charts"
  chart             = "prometheus-pushgateway"
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  # dependency_update = true
  version           = var.Settings.clusters[var.Cluster].versions.pushgateway.chart_version
  repository_username = data.vault_kv_secret_v2.artifactory_creds.data["user"]
  repository_password = data.vault_kv_secret_v2.artifactory_creds.data["password"]
  repository_cert_file = var.artifactoryRepoDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.crt" : null
  repository_key_file  = var.artifactoryRepoDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.key" : null

  values = [
    templatefile("${path.module}/pushgateway-values.yaml", {})
  ]
}
