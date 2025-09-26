resource "vault_policy" "ccr" {
  name   = "ccr"
  policy = <<EOT
path "secret/data/red/wl/ccr/*" {
  capabilities = ["read","list"]
}
EOT
}