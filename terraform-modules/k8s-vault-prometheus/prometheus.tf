data "vault_generic_secret" "oidc_secrets" {
  path = var.OidcSecretVaultPath
}

data "vault_generic_secret" "grafana" {
  path = "secret/grafana"
}

resource "helm_release" "prometheus" {
  name              = "prometheus"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "kube-prometheus-stack"
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
  version = "15.3.1"
  values = [
    file("${path.module}/kube-prometheous-stack-values.yaml")
  ]
  set {
    name  = "grafana.adminPassword"
    value = data.vault_generic_secret.grafana.data.adminPassword
  }
  set {
    name  = "grafana.grafana\\.ini.server.root_url"
    value = data.vault_generic_secret.grafana.data.root_url
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.google.client_id"
    value = data.vault_generic_secret.oidc_secrets.data.oidc_client_id
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.google.client_secret"
    value = data.vault_generic_secret.oidc_secrets.data.oidc_client_secret
  }
}
