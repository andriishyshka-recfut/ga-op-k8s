resource "vault_policy" "twirl" {
  name = "twirl"

  policy = <<EOT
path "secret/data/elasticsearch-admin/elastic7-v2" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
