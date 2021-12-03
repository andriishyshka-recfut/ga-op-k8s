
resource "vault_policy" "external_secrets" {
  name = "external-secrets"

  policy = <<EOT
path "secret/data/goharbor/*" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
EOT
}
