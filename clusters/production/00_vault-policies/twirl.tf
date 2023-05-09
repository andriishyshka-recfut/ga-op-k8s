resource "vault_policy" "twirl" {
  name = "twirl"

  policy = <<EOT
path "secret/data/twirl/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/twirl" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaTwirl" {
  capabilities = ["read","list"]
}
EOT
}
