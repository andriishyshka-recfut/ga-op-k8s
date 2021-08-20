


data "kubectl_file_documents" "topics" {
    content = file("${path.module}/kafka-topics.yaml")
}

resource "kubectl_manifest" "topics" {
    count     = 20
    yaml_body = element(data.kubectl_file_documents.topics.documents, count.index)
    depends_on = [
      helm_release.kafka_cluster
    ]
}
