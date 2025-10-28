resource "vault_policy" "busta" {
  name   = "busta"
  policy = <<EOT
path "secret/data/wl/busta/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/clicker/engine-definer" {
  capabilities = ["read","list"]
}
EOT
}