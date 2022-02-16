data "kubectl_file_documents" "istio_yaml" {
  content = file("${path.module}/istio.yaml")
}
resource "kubectl_manifest" "istio" {
  force_new = true
  count     = 3
  yaml_body = element(data.kubectl_file_documents.istio_yaml.documents, count.index)
}
