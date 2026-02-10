resource "vault_policy" "minion" {
  name   = "minion"
  policy = <<EOT
path "secret/data/minio/users" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/minion" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaMinion" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/production" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaMinion" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/minion/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/misc/slack/app/CDA" {
   capabilities = ["read","list"]
}
EOT
}
