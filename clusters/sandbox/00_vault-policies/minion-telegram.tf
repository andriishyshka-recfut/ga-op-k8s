resource "vault_policy" "minion-telegram" {
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
EOT
}