data "kubectl_file_documents" "etl_rules" {
  # content = file("${path.module}/go-prometheusrule.yaml")
  content = templatefile("${path.module}/etl-jobs.yaml", { cluster_label : var.Cluster, cluster_color : var.Color })
}

resource "kubectl_manifest" "etl_rules" {
  count     = 1
  yaml_body = element(data.kubectl_file_documents.etl_rules.documents, count.index)
}