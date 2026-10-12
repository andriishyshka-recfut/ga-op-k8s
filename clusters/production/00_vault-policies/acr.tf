resource "vault_policy" "acr" {
  name   = "acr"
  policy = <<EOT
path "secret/data/acr/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/swirl_telegram-yolo_models" {
  capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/ocr_telegram-attachments" {
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
path "secret/data/mongo/metaOcr" {
   capabilities = ["read","list"]
}
path "secret/data/mongo/metaOS3c" {
   capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/os3_telegram-attachments" {
   capabilities = ["read","list"]
}
EOT
}
