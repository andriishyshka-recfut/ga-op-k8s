resource "vault_policy" "tarantool" {
  name = "tarantool"

  policy = <<EOT

path "secret/data/mw/tarantool/*" {
  capabilities = ["read","list"]
}
EOT
}
