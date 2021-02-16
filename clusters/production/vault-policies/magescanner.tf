
resource "vault_policy" "magescanner" {
  name = "magescanner"

  policy = <<EOT
path "secret/es-creds-compose-prod/magescanner" {
  capabilities = ["read","list"]
}
path "secret/mongo/production" {
  capabilities = ["read","list"]
}
path "secret/magescanner/google_service_account" {
  capabilities = ["read","list"]
}
path "secret/magescanner/geoip_secret_config" {
  capabilities = ["read","list"]
}
path "secret/magescanner/splash-vpn" {
  capabilities = ["read","list"]
}
path "secret/oidc_google_prod" {
  capabilities = ["read","list"]
}
EOT
}
