resource "vault_policy" "rail" {
  name = "rail"

  policy = <<EOT
path "secret/data/wl/rail*" {
  capabilities = ["read","list"]
}
path "/secret/data/misc/cybera/gemini" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaBeat" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaRail" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
    capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaMule" {
    capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_mule.ms" {
    capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
