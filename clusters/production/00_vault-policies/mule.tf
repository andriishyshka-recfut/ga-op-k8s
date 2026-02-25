resource "vault_policy" "mule" {
  name = "mule"

  policy = <<EOT
path "secret/data/elasticsearch-admin/elastic7-v2" {
  capabilities = ["read","list"]
}
path "secret/data/wl/mule*" {
  capabilities = ["read","list"]
}
path "/secret/data/misc/cybera/gemini" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/production" {
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
path "secret/data/es-creds-compose-prod/_ms.mule" {
    capabilities = ["read","list"]
}
EOT
}
