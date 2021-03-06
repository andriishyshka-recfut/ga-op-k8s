resource "vault_policy" "maid" {
  name = "maid"

  policy = <<EOT
path "secret/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
path "secret/oidc_google_test" {
  capabilities = ["read","list"]
}
EOT
}
