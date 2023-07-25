data "kubectl_file_documents" "bots_status_yaml" {
  content = file("${path.module}/bots-status.yaml")
}
resource "kubectl_manifest" "bots_status" {
  force_new = true
  count     = 1
  yaml_body = element(data.kubectl_file_documents.bots_status_yaml.documents, count.index)
}
