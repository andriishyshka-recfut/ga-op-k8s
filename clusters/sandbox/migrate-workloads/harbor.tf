
data "google_service_account" "vault_sa" {
  account_id = "vault-sandbox"
}

resource "google_service_account_key" "harbor_key" {
  service_account_id = data.google_service_account.vault_sa.name
}

data "google_project" "current" {}


resource "helm_release" "harbor" {
  name       = "harbor"
  chart      = "harbor"
  repository = "https://helm.goharbor.io"
  wait       = true
  atomic     = true
  namespace  = "harbor"
  version    = "v1.5.3"
  timeout    = 900

  values = [
    file("./harbor-values.yaml")
  ]
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
    value = google_service_account_key.harbor_key.private_key
  }

}


data "vault_auth_backend" "kubernetes" {
  path = "k8s-sandbox-green"
}

resource "vault_policy" "harbor" {
  name = "harbor"

  policy = <<EOT
path "secret/minio/users" {
  capabilities = ["read","list"]
}
EOT
}


resource "vault_kubernetes_auth_backend_role" "harbor_role" {
  backend                          = data.vault_auth_backend.kubernetes.path
  role_name                        = "harbor"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["harbor"]
  token_ttl                        = 3600
  token_policies                   = ["harbor"]
}
