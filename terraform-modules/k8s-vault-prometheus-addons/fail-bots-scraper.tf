data "kubectl_file_documents" "fail_bots_scraper" {
  content = file("${path.module}/fail_bots_scraper.yaml")
}
resource "kubectl_manifest" "fail_bots_scraper" {
  force_new = true
  count     = 1
  yaml_body = element(data.kubectl_file_documents.fail_bots_scraper.documents, count.index)
}
