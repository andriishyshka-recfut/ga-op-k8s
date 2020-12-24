
data "google_service_account" "vault_sa" {
  account_id = "vault-sandbox"
}

resource "google_service_account_key" "harbor-key" {
  service_account_id = data.google_service_account.vault-sa.name
}



resource "helm_release" "harbor" {
  name       = "harbor"
  chart      = "harbor"
  repository = "https://helm.goharbor.io"
  wait       = true
  atomic     = true
  namespace  = "harbor"
  version    = "v1.4.3"
  timeout    = 900
  set {
    name  = "expose.type"
    value = "ClusterIP"
  }
  set {
    name  = "expose.clusterIP.name"
    value = "harbor"
  }
  set {
    name  = "expose.tls.enabled"
    value = "false"
  }
  set {
    name  = "externalURL"
    value = "https://harbor.infra.digaweb.com"
  }
  set {
    name  = "persistence.imageChartStorage.type"
    value = "gcs"
  }
  set {
    name  = "persistence.imageChartStorage.gcs.bucket"
    value = "harbor-backet-${data.google_project.current.project_id}"
  }
  set {
    name  = "persistence.imageChartStorage.gcs.encodedkey"
    value = google_service_account_key.harbor-key.private_key
  }
}
