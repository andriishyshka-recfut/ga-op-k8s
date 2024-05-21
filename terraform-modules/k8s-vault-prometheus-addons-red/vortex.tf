data "kubectl_file_documents" "vortex_yaml" {
  content = file("${path.module}/vortex.yaml")
}


resource "kubectl_manifest" "vortex" {
  # force_new = true
  count     = 1
  yaml_body = element(data.kubectl_file_documents.vortex_yaml.documents, count.index)
}
