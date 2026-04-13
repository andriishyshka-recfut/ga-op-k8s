resource "vault_policy" "minion_telegram" {
  name = "minion-telegram"

  policy = <<EOT
path "secret/data/mw/monitoring/otel" {
  capabilities = ["read", "list"]
}
path "secret/data/wl/minion/minio" {
  capabilities = ["read", "list"]
}
path "secret/data/wl/minion/+/telegram-creds" {
  capabilities = ["read", "list"]
}
path "secret/data/mw/minio/sa/unitedfullz_unitedfullz" {
  capabilities = ["read", "list"]
}
path "secret/data/wl/minion/circinus/telegram-creds" {
  capabilities = ["read", "list"]
}
EOT
}