# data "kubectl_file_documents" "bots_status_yaml" {
#   content = file("${path.module}/bots-status.yaml")
# }
# resource "kubernetes_manifest" "bots_status" {
#   count     = 1
#   manifest = yamldecode(element(data.kubectl_file_documents.bots_status_yaml.documents, count.index))
# }
