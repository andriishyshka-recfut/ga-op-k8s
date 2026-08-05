resource "vault_policy" "mapper" {
  name = "mapper"

  policy = <<EOT
path "/secret/data/wl/mapper/*" {
  capabilities = ["read","list"]
}
path "/secret/data/mw/monitoring/otel" {
  capabilities = ["read","list"]
}
path "/secret/data/es-creds-compose-prod/metaGrouper" {
  capabilities = ["read","list"]
}
path "/secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "/secret/data/es-creds-compose-prod/_grouper.ms" {
  capabilities = ["read","list"]
}
path "/secret/data/mongo/metaGrouper" {
  capabilities = ["read","list"]
}
path "/secret/data/misc/slack/app/grouper" {
  capabilities = ["read","list"]
}
path "/secret/data/wl/ai/chatgpt/grouper" {
  capabilities = ["read","list"]
}
EOT
}