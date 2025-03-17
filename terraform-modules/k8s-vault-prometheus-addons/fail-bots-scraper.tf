# data "kubectl_file_documents" "fail_bots_scraper" {
#   content = file("${path.module}/fail-bots-scraper.yaml")
# }
# resource "kubernetes_manifest" "fail_bots_scraper" {
#   count     = 1
#   manifest = yamldecode(element(data.kubectl_file_documents.fail_bots_scraper.documents, count.index))
# }
