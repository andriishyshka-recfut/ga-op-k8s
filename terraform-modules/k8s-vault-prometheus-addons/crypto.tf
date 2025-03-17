# data "kubectl_file_documents" "crypto_rules" {
#   content = templatefile("${path.module}/crypto.yaml", { cluster_label : var.Cluster, cluster_color : var.Color })
# }

# resource "kubernetes_manifest" "crypto_rules" {
#   count     = 1
#   manifest = yamldecode(element(data.kubectl_file_documents.crypto_rules.documents, count.index))
# }
