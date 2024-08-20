data "kubectl_file_documents" "cert_manager_yaml" {
  content = file("${path.module}/cert-manager.yaml")
}
resource "kubernetes_manifest" "cert-manager" {
  count     = 2
  manifest = yamldecode(element(data.kubectl_file_documents.cert_manager_yaml.documents, count.index))
}
