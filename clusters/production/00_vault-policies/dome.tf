

resource "vault_policy" "dome" {
  name = "dome"

  policy = <<EOT
path "secret/data/minio/users" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/dome" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/production" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaDome" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaDome" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
EOT
}
