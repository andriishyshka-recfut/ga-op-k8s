resource "vault_policy" "maid" {
  name   = "maid"
  policy = <<EOT
path "secret/data/es-creds-compose-prod/maid/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaWhistle" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_whistle.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "secret/data/oidc_google_prod" {
  capabilities = ["read","list"]
}
path "secret/data/wl/maid/*" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaBeat" {
  capabilities = ["read","list"]
}
path "secret/data/oidc/vault_token" {
  capabilities = ["read","list"]
}
path "secret/data/misc/oidc/okta/maid" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/misc/slack/app/MAID" {
   capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/clean_maid" {
   capabilities = ["read","list"]
}
EOT
}
