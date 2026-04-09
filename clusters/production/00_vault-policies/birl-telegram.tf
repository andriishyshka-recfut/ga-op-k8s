resource "vault_policy" "birl-telegram" {
  name   = "birl-telegram"
  policy = <<EOT
path "secret/data/acr/vision/*" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaBirl" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaBeat" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaBirl" {
  capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/birl_telegram-attachments" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaBirlApi" {
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
path "secret/data/es-creds-compose-prod/_birl.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaBirlDatafix"{
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaUpsertBirl"{
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaBeatBirlMs"{
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/datafix"{
  capabilities = ["read","list"]
}
path "secret/data/wl/birl/*"{
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "postgres/creds/*" {
  capabilities = ["read","list","create","update"]
}
EOT
}
