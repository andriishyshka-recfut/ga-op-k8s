data "kubectl_file_documents" "crypto_rules" {
  content = templatefile("${path.module}/crypto.yaml", { cluster_label : var.Cluster, cluster_color : var.Color })
}

resource "kubectl_manifest" "crypto_rules" {
  count     = 1
  yaml_body = element(data.kubectl_file_documents.crypto_rules.documents, count.index)
}
