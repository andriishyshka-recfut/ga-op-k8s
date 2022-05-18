
resource "helm_release" "es_exporter" {
  name              = "es-exporter"
  repository        = "https://braedon.github.io/helm"
  chart             = "prometheus-es-exporter"
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
  # version           = local.helmVersion
  values = [
    file("${path.module}/es-exporter-values.yaml")
  ]
  depends_on = [helm_release.prometheus]
}

data "kubectl_file_documents" "es_exporter" {
  content = file("${path.module}/es-exporter-servicemonitor.yaml")
}

resource "kubectl_manifest" "es_exporter" {
  count     = 1
  yaml_body = element(data.kubectl_file_documents.es_exporter.documents, count.index)
}
data "kubectl_file_documents" "es_exporter_rules" {
  # content = file("${path.module}/es-exporter-prometheusrule.yaml")
  content = templatefile("${path.module}/es-exporter-prometheusrule.yaml", { cluster_label : var.Cluster })
}

resource "kubectl_manifest" "es_exporter_rules" {
  count     = 1
  yaml_body = element(data.kubectl_file_documents.es_exporter_rules.documents, count.index)
}
