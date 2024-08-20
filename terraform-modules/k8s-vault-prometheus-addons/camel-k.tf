data "kubectl_file_documents" "camel_yaml" {
  content = file("${path.module}/camel-k.yaml")
}
resource "kubernetes_manifest" "camel" {
  count     = 1
  manifest = yamldecode(element(data.kubectl_file_documents.camel_yaml.documents, count.index))
}
