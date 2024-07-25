data "kubectl_file_documents" "wordpress-prometheusrule" {
  content = file("${path.module}/wordpress-prometheusrule.yaml")
}
resource "kubectl_manifest" "wordpress-prometheusrule" {
  force_new = true
  count     = 1
  yaml_body = element(data.kubectl_file_documents.wordpress-prometheusrule.documents, count.index)
}

data "kubectl_file_documents" "wordpress-servicemonitor" {
  content = file("${path.module}/wordpress-servicemonitor.yaml")
}
resource "kubectl_manifest" "wordpress-servicemonitor" {
  force_new = true
  count     = 1
  yaml_body = element(data.kubectl_file_documents.wordpress-servicemonitor.documents, count.index)
}