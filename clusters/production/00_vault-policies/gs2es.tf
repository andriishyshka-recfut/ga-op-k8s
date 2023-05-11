resource "vault_policy" "gs2es" {
  name = "gs2es"

  policy = <<EOT
path "secret/data/gs2es/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/gs2es" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaGs2es" {
  capabilities = ["read","list"]
}
EOT
}