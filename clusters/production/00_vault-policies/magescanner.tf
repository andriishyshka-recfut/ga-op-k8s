
resource "vault_policy" "magescanner" {
  name = "magescanner"

  policy = <<EOT
path "secret/data/es-creds-compose-prod/magescanner" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/production" {
  capabilities = ["read","list"]
}
path "secret/data/magescanner/google_service_account" {
  capabilities = ["read","list"]
}
path "secret/data/magescanner/geoip_secret_config" {
  capabilities = ["read","list"]
}
path "secret/data/magescanner/*" {
  capabilities = ["read","list"]
}
path "secret/data/magescanner/splash-vpn" {
  capabilities = ["read","list"]
}
path "secret/data/oidc_google_prod" {
  capabilities = ["read","list"]
}
EOT
}
