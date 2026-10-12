
resource "vault_policy" "magescanner" {
  name   = "magescanner"
  policy = <<EOT
path "secret/data/es-creds-compose-prod/magescanner" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaMage*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaUpsertmageMs" {
    capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaCppMage" {
    capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
    capabilities = ["read","list"]
}
path "secret/data/mongo/production" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaMage*" {
  capabilities = ["read","list"]
}
path "secret/data/magescanner/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/magescanner/*" {
  capabilities = ["read","list"]
}
path "secret/data/oidc_google_prod" {
  capabilities = ["read","list"]
}
path "secret/data/minio/similarweb" {
  capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/similarweb_similarweb" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/similarweb" {
	capabilities = ["read","list"]
}
path "secret/data/mongo/metaBeat" {
	capabilities = ["read","list"]
}
path "secret/magescanner/whoer_vpn" {
  capabilities = ["read","list"]
}
path "secret/magescanner/surfshark_creds" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/magescanner_mgscn" {
   capabilities = ["read","list"]
}
path "pki-minio/cert/ca" {
  capabilities = ["read"]
}
EOT
}
