
data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
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
    file("${path.module}/blackbox-values.yaml")
  ]
  set {
    name = "config.modules.harbor.http.basic_auth.username"
    value = data.vault_generic_secret.harbor_token.data.user
  }
  set {
    name = "config.modules.harbor.http.basic_auth.password"
    value = data.vault_generic_secret.harbor_token.data.password
  }
  depends_on = [
        helm_release.prometheus
    ]
}


data "kubectl_file_documents" "blackbox_probes" {
    content = file("${path.module}/blackbox-probes.yaml")
}

resource "kubectl_manifest" "blackbox_probes" {
    count = 2
    yaml_body  = element(data.kubectl_file_documents.blackbox_probes.documents, count.index)
    override_namespace = local.prometheusNs
    depends_on = [
        helm_release.blackbox_exporter
    ]
}
