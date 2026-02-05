resource "vault_policy" "oidc" {
  name = "oidc"

  policy = <<EOT

path "secret/data/oidc_google_test" {
  capabilities = ["read","list"]
}
path "secret/data/misc/oidc/okta/*" {
  capabilities = ["read","list"]
}
EOT
}
