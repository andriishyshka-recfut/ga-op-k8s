data "kubectl_file_documents" "pi_query_expensive" {
  content = file("${path.module}/pi-expensive-alert.yaml")
}
resource "kubectl_manifest" "pi_query_expensive" {
  force_new = true
  count     = 1
  yaml_body = element(data.kubectl_file_documents.pi_query_expensive.documents, count.index)
}
