resource "vault_policy" "backup" {
  name = "backup"

  policy = <<EOT
path "secret/data/backup/*" {
  capabilities = ["read","list"]
}
EOT
}
