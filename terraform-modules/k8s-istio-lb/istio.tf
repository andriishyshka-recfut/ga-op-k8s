data "vault_kv_secret_v2" "artifactory_creds" {
  mount = "secret"
  name  = "misc/artifactory/creds"
}
resource "helm_release" "istio_ingress_lb" {
  for_each             = local.istio_ingresses
  name                 = "istio-ingressgateway-${each.key}"
  chart                = "gateway"
  repository           = "oci://${var.RepositoryDomain}/ga-helm-virtual/istio/release/charts"
  version              = var.Settings.clusters[var.Cluster].versions.istio.helm_version
  wait                 = true
  atomic               = true
  namespace            = "istio-ingress"
  repository_username  = data.vault_kv_secret_v2.artifactory_creds.data["user"]
  repository_password  = data.vault_kv_secret_v2.artifactory_creds.data["password"]
  repository_cert_file = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.crt" : null
  repository_key_file  = var.RepositoryDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.key" : null
  values = [
    templatefile("${path.module}/values.tftpl", { settings = each.value })
  ]
}
