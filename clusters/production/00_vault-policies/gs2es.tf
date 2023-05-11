resource "vault_policy" "gs2es" {
  name = "gs2es"

  policy = <<EOT
path "secret/data/gs2es/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/gs2es" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaGs2esCppMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticHosts" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCa" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_gs2es-cpp.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticKey" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCrt" {
  capabilities = ["read","list"]
}
EOT
}