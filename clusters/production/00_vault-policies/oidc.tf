resource "vault_policy" "oidc" {
  name   = "oidc"
  policy = <<EOT
path "secret/data/oidc_google_prod" {
  capabilities = ["read","list"]
}
path "secret/data/oidc/*" {
  capabilities = ["read","list"]
}
path "secret/data/misc/oidc/*" {
  capabilities = ["read","list"]
}
EOT
}
