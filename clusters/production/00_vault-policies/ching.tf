resource "vault_policy" "ching" {
  name   = "ching"
  policy = <<EOT
path "secret/data/core/ching/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
