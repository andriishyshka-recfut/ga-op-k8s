

resource "vault_policy" "minion" {
  name = "minion"

  policy = <<EOT
path "secret/data/minio/users" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/minion" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/magescanner" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
EOT
}
