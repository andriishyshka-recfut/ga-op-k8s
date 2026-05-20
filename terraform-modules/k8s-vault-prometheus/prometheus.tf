data "vault_generic_secret" "oidc_secrets" {
  path = var.OidcSecretVaultPath
}

data "vault_generic_secret" "grafana" {
  path = local.grafanaSecretpath
}

data "vault_generic_secret" "prometheus" {
  path = local.slackSecretPath
}

data "vault_generic_secret" "minio" {
  path = "secret/minio/users"
}

resource "kubernetes_secret" "thanos-objstore-config" {
  metadata {
    name      = "thanos-objstore-config"
    namespace = local.prometheusNs
  }

  data = { 
    "objstore.yml" = <<EOF
type: s3
config:
  bucket: ${local.thanosBucket}
  endpoint: minio.minio:9000
  insecure: true
  access_key: ${jsondecode(data.vault_generic_secret.minio.data[local.thanosMinioUser]).accessKey}
  secret_key: ${jsondecode(data.vault_generic_secret.minio.data[local.thanosMinioUser]).secretKey}
EOF
  }
}
resource "kubernetes_secret" "grafana_okta_client_secret" {
  metadata {
    name      = "grafana-okta-client-secret"
    namespace = local.prometheusNs
  }
  data = {
    client_secret = data.vault_generic_secret.okta_oidc.data.client_secret
  }
}

resource "kubernetes_priority_class" "monitoring_high" {
  metadata {
    name = "monitoring-high"
  }

  value              = 1000000
  description        = "High priority for monitoring exporters"
  global_default     = false
  preemption_policy  = "PreemptLowerPriority"
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
  take_ownership    = false
  upgrade_install   = false
  values = [
    templatefile("${path.module}/${local.prometheusConfigFile}", {
      prometheus_slack_webhooks          = local.prometheusSlackWebHooks,
      grafana_creds                      = data.vault_generic_secret.grafana.data,
      grafana_auth_google                = data.vault_generic_secret.oidc_secrets.data,
      grafana_users_auto_assign_org_role = local.grafanaRole,
      prometheus_external_url            = local.prometheusExtUrl,
      additional_rule_labels             = var.Cluster,
      thanos_version                     = local.thanosSidecarVersion,
      prometheus_query_url               = local.prometheusQueryUrl,
      prometheus_resources               = local.prometheusResources,
      priority_class                     = kubernetes_priority_class.monitoring_high.metadata.0.name,
      okta                               = local.grafana_okta,
      cluster                            = var.Cluster
    })
  ]
}
