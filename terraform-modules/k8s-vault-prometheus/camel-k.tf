data "kubectl_file_documents" "camel_yaml" {
  content = file("${path.module}/camel-k.yaml")
}
resource "kubectl_manifest" "camel" {
  force_new = true
  count     = 1
  yaml_body = element(data.kubectl_file_documents.camel_yaml.documents, count.index)
}
