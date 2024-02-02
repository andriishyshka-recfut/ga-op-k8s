# locals {
#   grafanaValues = yamldecode(file("${path.module}/values.yaml"))
# }
data "vault_generic_secret" "elastic" {
  path = "secret/elasticsearch-admin/elastic"
}
data "vault_generic_secret" "grafana" {
  path = local.grafanaSecretpath
}
data "vault_generic_secret" "oidc_secrets" {
  path = "secret/oidc_google_prod"
}

resource "helm_release" "grafana-clients" {
  name          = "grafana-clients"
  chart         = "grafana"
  version       = local.helmVersion
  repository    = "https://grafana.github.io/helm-charts"
  wait          = true
  atomic        = true
  force_update  = true
  namespace     = "grafana-clients"
  # values = [
  #   yamlencode(local.grafanaValues)
  # ]
  values = [
    "${file("${path.module}/values.yaml")}"
  ]
  set {
    name  = "adminPassword"
    value = data.vault_generic_secret.grafana.data.password
  }
  set {
    name  = "grafana\\.ini.server.root_url"
    value = data.vault_generic_secret.grafana.data.root_url
  }
  set {
    name  = "grafana\\.ini.auth\\.google.client_id"
    value = data.vault_generic_secret.oidc_secrets.data.oidc_client_id
  }
  set {
    name  = "grafana\\.ini.auth\\.google.client_secret"
    value = data.vault_generic_secret.oidc_secrets.data.oidc_client_secret
  }
  set {
    name  = "grafana\\.ini.users.auto_assign_org_role"
    value = local.grafanaRole
  }
}
provider "grafana" {}