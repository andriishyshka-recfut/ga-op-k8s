
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
}

data "kubectl_file_documents" "es_exporter" {
  content = file("${path.module}/es-exporter-servicemonitor.yaml")
}

resource "kubernetes_manifest" "es_exporter" {
  count     = 1
  manifest = yamldecode(element(data.kubectl_file_documents.es_exporter.documents, count.index))
}
