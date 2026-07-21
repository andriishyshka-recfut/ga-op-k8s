resource "vault_policy" "review" {
  name   = "review"
  policy = <<EOT
path "secret/data/mongo/metaReviewMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/binsightMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaBinsightMs" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaBinsight" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
