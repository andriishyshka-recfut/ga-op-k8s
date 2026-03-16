resource "vault_policy" "clicker" {
  name   = "clicker"
  policy = <<EOT
path "secret/data/wl/clicker/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/clicker" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaClicker" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/production" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaClicker" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
path "secret/data/oidc_google_prod" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/clicker_clicker" {
  capabilities = ["read","list"]
}
EOT
}
