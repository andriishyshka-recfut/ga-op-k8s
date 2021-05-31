resource "vault_policy" "backup" {
  name = "backup"

  policy = <<EOT
path "secret/backup/*" {
  capabilities = ["read","list"]
}
EOT
}
