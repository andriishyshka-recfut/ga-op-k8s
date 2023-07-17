
data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}




data "vault_generic_secret" "es_access" {
  path = "secret/es-creds-compose-prod/prometheus"
}

data "vault_generic_secret" "vortex_basic_auth" {
  count = local.vortex
  path  = "secret/tls-proxy/basic-auth/vortex"
}

resource "kubernetes_manifest" "vortex_cert" {
  count = local.vortex
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "vortex-cert"
      "namespace" = "monitoring"
    }
    "spec" = {
      "commonName" = "vortex.regemini.com"
      "dnsNames" = [
        "vortex.regemini.com"
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "vault-vortex-issuer"
      }
      "secretName" = "vortex-cert"
    }
  }
}

resource "kubernetes_secret" "es_creds" {
  metadata {
    name      = "es-secret"
    namespace = local.prometheusNs
  }

  data = {
    "ca_crt"     = data.vault_generic_secret.es_access.data.ELASTICSEARCH_CA_CRT
    "client_crt" = data.vault_generic_secret.es_access.data.ELASTICSEARCH_CLIENT_CRT
    "client_key" = data.vault_generic_secret.es_access.data.ELASTICSEARCH_CLIENT_KEY
  }

}

resource "kubernetes_secret" "vortex_basic_auth_creds" {
  count = local.vortex
  metadata {
    name      = "vortex-auth"
    namespace = local.prometheusNs
  }

  data = {
    "vortex" = data.vault_generic_secret.vortex_basic_auth[0].data.probe
  }

}

resource "helm_release" "blackbox_exporter" {
  name              = "blackbox-exporter"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "prometheus-blackbox-exporter"
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
    values = [
    templatefile("${path.module}/blackbox-values.yaml.tftpl", { vortex = local.vortex == 1 ? true : false })
  ]
  values = [
    file("")
  ]
  set {
    name  = "config.modules.harbor.http.basic_auth.username"
    value = data.vault_generic_secret.harbor_token.data.user
  }
  set {
    name  = "config.modules.harbor.http.basic_auth.password"
    value = data.vault_generic_secret.harbor_token.data.password
  }
  set {
    name  = "config.modules.elastic.http.basic_auth.username"
    value = data.vault_generic_secret.es_access.data.USERNAME
  }
  set {
    name  = "config.modules.elastic.http.basic_auth.password"
    value = data.vault_generic_secret.es_access.data.PASSWORD
  }
  set {
    name  = "prometheusRule.rules[0].labels.cluster"
    value = var.Cluster
  }
  set {
    name  = "prometheusRule.rules[1].labels.cluster"
    value = var.Cluster
  }
  set {
    name  = "prometheusRule.rules[2].labels.cluster"
    value = var.Cluster
  }
  set {
    name  = "prometheusRule.rules[3].labels.cluster"
    value = var.Cluster
  }
  set {
    name  = "prometheusRule.rules[4].labels.cluster"
    value = var.Cluster
  }
  depends_on = [kubernetes_secret.vortex_basic_auth_creds]
}


data "kubectl_file_documents" "blackbox_probes" {
  content = templatefile("${path.module}/blackbox-probes.yaml.tftpl", { vortex = local.vortex == 1 ? true : false })
}

resource "kubectl_manifest" "blackbox_probes" {
  count              = 5
  yaml_body          = element(data.kubectl_file_documents.blackbox_probes.documents, count.index)
  override_namespace = local.prometheusNs
  depends_on = [
    helm_release.blackbox_exporter
  ]
}


data "http" "grafana_dashboard_blackbox" {
  url = "https://grafana.com/api/dashboards/7587/revisions/3/download"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "blackbox_dashboards" {
  metadata {
    name      = "blackbox-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "blackbox.json" = replace(data.http.grafana_dashboard_blackbox.body, "$${DS_SIGNCL-PROMETHEUS}", "Prometheus")
  }

}
