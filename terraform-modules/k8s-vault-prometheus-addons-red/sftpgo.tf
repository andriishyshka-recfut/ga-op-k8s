data "kubectl_file_documents" "sftpgo" {
  content = file("${path.module}/sftpgo.yaml")
}

resource "kubectl_manifest" "sftpgo" {
  force_new = true
  count     = 2
  yaml_body = element(data.kubectl_file_documents.sftpgo.documents, count.index)
}