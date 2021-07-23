resource "vault_policy" "maid" {
  name = "maid"

  policy = <<EOT
path "secret/data/es-creds-compose-prod/maid/*" {
  capabilities = ["read","list"]
}
path "secret/data/oidc_google_prod" {
  capabilities = ["read","list"]
}
path "secret/data/slack/maid" {
  capabilities = ["read","list"]
}
EOT
}
