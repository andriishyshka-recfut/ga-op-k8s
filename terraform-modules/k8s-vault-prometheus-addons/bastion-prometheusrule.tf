data "kubectl_file_documents" "bastion-prometheusrule" {
  content = file("${path.module}/bastion-prometheusrule.yaml")
}

resource "kubectl_manifest" "bastion-prometheusrule" {
  force_new = true
  count     = 1
  yaml_body = element(data.kubectl_file_documents.bastion-prometheusrule.documents, count.index)
}

data "kubectl_file_documents" "bastion-servicemonitor" {
  content = file("${path.module}/bastion-servicemonitor.yaml")
}
resource "kubectl_manifest" "bastion-servicemonitor" {
  force_new = true
  count     = 1
  yaml_body = element(data.kubectl_file_documents.bastion-servicemonitor.documents, count.index)
}

resource "kubernetes_manifest" "bastion-prometheusrule" {
  count    = 3
  manifest = yamldecode(element(data.kubectl_file_documents.bastion-prometheusrule.documents, count.index))
}

resource "kubernetes_manifest" "bastion-servicemonitor" {
  count    = 2
  manifest = yamldecode(element(data.kubectl_file_documents.bastion-servicemonitor.documents, count.index))
}
