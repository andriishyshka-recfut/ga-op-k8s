


data "kubectl_file_documents" "topics" {
    content = file("${path.module}/kafka-topics.yaml")
}

resource "kubectl_manifest" "topics" {
    count     = length(data.kubectl_file_documents.topics.documents)
    yaml_body = element(data.kubectl_file_documents.topics.documents, count.index)
}
