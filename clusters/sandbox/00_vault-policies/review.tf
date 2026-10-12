resource "vault_policy" "review" {
  name   = "review"
  policy = <<EOT
path "secret/data/mw/monitoring/otel" {
  capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/elastic7-v2" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/sandbox" {
  capabilities = ["read","list"]
}
EOT
}
