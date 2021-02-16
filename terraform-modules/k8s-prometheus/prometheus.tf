data "vault_generic_secret" "oidc_secrets" {
  path = "secret/oidc_google_prod"
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
  values = [
    templatefile("${path.module}/values.tmpl",
      {
        CLIENT_ID     = data.vault_generic_secret.oidc_secrets.data.oidc_client_id
        CLIENT_SECRET = data.vault_generic_secret.oidc_secrets.data.oidc_client_secret
        ROOT_URL      = data.vault_generic_secret.grafana.data.ROOT_URL
      }
    )
  ]
  set {
    name  = "podAnnotations.sidecar\\.istio\\.io/inject"
    value = " False"
  }
}
