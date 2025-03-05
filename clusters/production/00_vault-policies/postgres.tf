resource "vault_policy" "postgres" {
  name   = "postgres"
  policy = <<EOT
path "secret/data/mw/postgres/db-users/*" {
  capabilities = ["read","list"]
}
path "secret/metadata/mw/postgres/db-users/*" {
  capabilities = ["read","list"]
}
EOT
}
