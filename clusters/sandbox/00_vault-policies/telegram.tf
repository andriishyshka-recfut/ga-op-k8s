resource "vault_policy" "telegram" {
  name = "telegram"

  policy = <<EOT
path "secret/data/telegram/telegram" {
  capabilities = ["read", "list"]
}
path "secret/data/mongo/sandbox" {
  capabilities = ["read", "list"]
}
path "secret/data/mw/monitoring/otel" {
  capabilities = ["read", "list"]
}
path "secret/data/elasticsearch-admin/elastic7-v2" {
  capabilities = ["read","list"]
}
path "secret/data/telegram/os3/minio-attachment" {
  capabilities = ["read","list"]
}
path "secret/data/wl/datafix/datafix/birl" {
  capabilities = ["read","list"]
}
EOT
}