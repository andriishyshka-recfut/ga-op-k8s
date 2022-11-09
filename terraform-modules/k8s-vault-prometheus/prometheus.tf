data "vault_generic_secret" "oidc_secrets" {
  path = var.OidcSecretVaultPath
}

data "vault_generic_secret" "grafana" {
  path = local.grafanaSecretpath
}

data "vault_generic_secret" "prometheus" {
  path = "secret/slack/prometheus"
}

data "vault_generic_secret" "thanos" {
  path = "secret/thanos/minio"
}

resource "kubernetes_secret" "thanos-objstore-config" {
  metadata {
    name      = "thanos-objstore-config"
    namespace = local.prometheusNs
  }

  data = { "thanos.yaml" = <<EOF
type: s3
config:
  bucket: ${local.thanosBucket}
  endpoint: minio.minio:9000
  insecure: true
  access_key: ${data.vault_generic_secret.thanos.data.access_key}
  secret_key: ${data.vault_generic_secret.thanos.data.secret_key}
EOF
  
   }

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
    file("${path.module}/${local.prometheusConfigFile}")
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
  set {
    name  = "prometheus.prometheusSpec.thanos.version"
    value = local.thanosSidecarVersion
  }
}
