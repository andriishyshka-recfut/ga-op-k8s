resource "vault_policy" "whirl" {
  name = "whirl"

  policy = <<EOT
path "secret/data/whirl/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/whirl" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaWhirl" {
  capabilities = ["read","list"]
}
EOT
}
