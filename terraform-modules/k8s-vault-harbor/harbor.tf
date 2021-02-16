
data "google_service_account" "vault_sa" {
  account_id = "vault-sandbox"
}

resource "google_service_account_key" "harbor_key" {
  service_account_id = data.google_service_account.vault_sa.name
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

  values = [
    file("${path.module}/harbor-values.yaml")
  ]
  set {
    name  = "persistence.imageChartStorage.type"
    value = "gcs"
  }
  set {
    name  = "persistence.imageChartStorage.gcs.bucket"
    value = "harbor-backet-${local.currentProject}"
  }
  set {
    name  = "persistence.imageChartStorage.gcs.encodedkey"
    value = google_service_account_key.harbor_key.private_key
  }

}
