data "kubectl_file_documents" "cert_manager_yaml" {
  content = file("${path.module}/cert-manager.yaml")
}
resource "kubectl_manifest" "cert-manager" {
  force_new = true
  count     = 2
  yaml_body = element(data.kubectl_file_documents.cert_manager_yaml.documents, count.index)
}
