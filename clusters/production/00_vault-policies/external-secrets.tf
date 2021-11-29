
resource "vault_policy" "external_secrets" {
  name = "external-secrets"

  policy = <<EOT
path "secret/data/goharbor/*" {
  capabilities = ["read","list"]
}
EOT
}
