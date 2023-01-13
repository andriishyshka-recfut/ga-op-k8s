resource "vault_policy" "datafix" {
  name = "datafix"

  policy = <<EOT
path "secret/data/mongo/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/*" {
  capabilities = ["read","list"]
}
EOT
}
