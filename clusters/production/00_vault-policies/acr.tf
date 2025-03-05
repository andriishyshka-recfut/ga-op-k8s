resource "vault_policy" "acr" {
  name   = "acr"
  policy = <<EOT
path "secret/data/acr/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaOcr" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticHosts" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCa" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCrt" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticKey" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_ocr.ms" {
  capabilities = ["read","list"]
}
path "secret/data/telegram/telegram" {
   capabilities = ["read","list"]
}
EOT
}
