data "kubectl_file_documents" "generic_rules" {
  # content = file("${path.module}/go-prometheusrule.yaml")
  content = templatefile("${path.module}/generic-prometheusrules.yaml", { cluster_label : var.Cluster , cluster_color : var.Color})
}

resource "kubectl_manifest" "generic_rules" {
  count     = 1
  yaml_body = element(data.kubectl_file_documents.generic_rules.documents, count.index)
}

