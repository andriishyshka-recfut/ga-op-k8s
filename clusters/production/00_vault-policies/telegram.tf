resource "vault_policy" "telegram" {
  name   = "telegram"
  policy = <<EOT
path "secret/data/minio/users" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
path "sys/leases/*" {
 capabilities = ["read","list","create","update"]
}
path "auth/token/renew*" {
 capabilities = ["read","list","create","update"]
}
path "secret/data/mongo/telegram" {
 capabilities = ["read","list"]
}
path "secret/data/telegram/*" {
 capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/telegram_telegram-sessions" {
   capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/os3_telegram-attachments" {
   capabilities = ["read","list"]
}
path "secret/data/mongo/metaBeat" {
 capabilities = ["read","list"]
}
path "secret/data/mongo/metaOS3t" {
 capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/beatTelegramMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaBeatTelegramMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaTelegram" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/telegram" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
