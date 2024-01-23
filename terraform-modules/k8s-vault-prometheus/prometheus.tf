data "vault_generic_secret" "oidc_secrets" {
  path = var.OidcSecretVaultPath
}

data "vault_generic_secret" "grafana" {
  path = local.grafanaSecretpath
}

data "vault_generic_secret" "prometheus" {
  path = "secret/slack/prometheus"
}

data "vault_generic_secret" "minio" {
  path = "secret/minio/users"
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
  access_key: ${jsondecode(data.vault_generic_secret.minio.data[local.thanosMinioUser]).accessKey}
  secret_key: ${jsondecode(data.vault_generic_secret.minio.data[local.thanosMinioUser]).secretKey}
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
    templatefile("${path.module}/${local.prometheusConfigFile}",{
      prometheus_slack_webhooks = local.prometheusSlackWebHooks,
      grafana_admin_pass        = data.vault_generic_secret.grafana.data.adminPassword,
      grafana_server_root_url   = data.vault_generic_secret.grafana.data.root_url,
      grafana_auth_google_client_id = data.vault_generic_secret.oidc_secrets.data.oidc_client_id,
      grafana_auth_google_client_id = data.vault_generic_secret.oidc_secrets.data.oidc_client_secret,
      grafana_users_auto_assign_org_role = local.grafanaRole
      prometheus_external_url = local.prometheusExtUrl
      additional_rule_labels  = var.Cluster
      thanos_version = local.thanosSidecarVersion
    })
  ]
}
