resource "vault_policy" "maid" {
  name = "maid"

  policy = <<EOT
path "secret/es-creds-compose-prod/maid/*" {
  capabilities = ["read","list"]
}
path "secret/oidc_google_test" {
  capabilities = ["read","list"]
}
EOT
}
