data "vault_generic_secret" "oidc_secrets" {
  path = var.OidcSecretVaultPath
}

data "vault_generic_secret" "grafana" {
  path = "secret/grafana"
}

data "vault_generic_secret" "prometheus" {
  path = "secret/slack/prometheus"
}

resource "helm_release" "prometheus" {
  name              = "prometheus"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "kube-prometheus-stack"
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
  version           = local.helmVersion
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
  set {
    name  = "grafana.grafana\\.ini.users.auto_assign_org_role"
    value = local.grafanaRole
  }
  set {
    name  = "alertmanager.config.global.slack_api_url"
    value = data.vault_generic_secret.prometheus.data.url
  }
  set {
    name  = "alertmanager.config.receivers[4].slack_configs[0].api_url"
    value = data.vault_generic_secret.prometheus.data.url_critical
  }
  set {
    name  = "prometheus.prometheusSpec.externalUrl"
    value = local.prometheusExtUrl
  }
  set {
    name  = "alertmanager.alertmanagerSpec.externalUrl"
    value = local.prometheusExtUrl
  }
  set {
    name  = "defaultRules.additionalRuleLabels.cluster"
    value = var.Cluster
  }
  set {
    name  = "defaultRules.rules.kubeProxy"
    value = false
  }
}
