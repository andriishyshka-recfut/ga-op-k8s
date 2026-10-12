resource "vault_policy" "oidc_pm" {
  name = "oidc-pm"
  policy = <<EOT
path "secret/data/wl/etl/clients/*" {
  capabilities = ["read","update","patch","create"]
}
path "secret/metadata/wl/etl/clients/*" {
  capabilities = ["read","list"]
}
EOT
}