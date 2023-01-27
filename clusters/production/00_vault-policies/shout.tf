resource "vault_policy" "shout" {
  name = "shout"

  policy = <<EOT
path "secret/data/shout/*" {
  capabilities = ["read","list","update"]
}
path "secret/data/es-creds-compose-prod/shout" {
  capabilities = ["read","list"]
}
EOT
}
