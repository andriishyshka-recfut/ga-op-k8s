data "kubectl_file_documents" "logstash_rules" {
  # content = file("${path.module}/go-prometheusrule.yaml")
  content = templatefile("${path.module}/logstash.yaml", { cluster_label : var.Cluster, cluster_color : var.Color })
}

# resource "kubectl_manifest" "logstash_rules" {
#   count     = 1
#   yaml_body = element(data.kubectl_file_documents.logstash_rules.documents, count.index)
# }

resource "kubernetes_manifest" "logstash_rules" {
  count    = 1
  manifest = yamldecode(element(data.kubectl_file_documents.logstash_rules.documents, count.index))
}
