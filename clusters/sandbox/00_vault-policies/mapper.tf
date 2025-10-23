resource "vault_policy" "mapper" {
  name = "mapper"

  policy = <<EOT
path "/secret/data/wl/mapper/*" {
  capabilities = ["read","list"]
}
path "/secret/data/mw/monitoring/otel" {
  capabilities = ["read","list"]
}
EOT
}