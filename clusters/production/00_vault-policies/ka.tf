resource "vault_policy" "ka" {
  name = "ka"

  policy = <<EOT
path "secret/data/ka/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/ka" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaKa" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/production" {
  capabilities = ["read","list"]
}
EOT
}
