resource "vault_policy" "whirl" {
  name   = "whirl"
  policy = <<EOT
path "secret/data/whirl/*" {
  capabilities = ["read","list"]
}
path "secret/data/telegram/os3/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/os3_telegram-attachments" {
   capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/whirl_telegram-attachments" {
   capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/whirl" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaWhirl" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticHosts" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCa" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_whirl.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticKey" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCrt" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaSanitizer" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
