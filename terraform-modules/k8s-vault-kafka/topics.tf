
/*
data "external" "kafka_topics" {
  program = ["python3", "read_topics.py"]
}

resource "kubectl_manifest" "default_setting_topics" {
  for_each = var.Cluster == "production" ? data.external.kafka_topics.result : {}
  yaml_body = templatefile("${path.module}/topic-default.yaml", {
    "TOPIC_NAME"          = each.value
    "TOPIC_RFC_1123_NAME" = each.key
  })
  depends_on = [
    helm_release.kafka_cluster
  ]
}
*/