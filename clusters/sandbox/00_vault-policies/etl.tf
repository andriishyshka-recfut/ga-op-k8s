resource "vault_policy" "etl" {
  name   = "etl"
  policy = <<EOT
path "secret/data/wl/etl/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/etl/clients/*" {
  capabilities = ["read","list"]
}
path "secret/metadata/wl/etl/*" {
  capabilities = ["read","list"]
}
path "secret/metadata/wl/etl/clients/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
