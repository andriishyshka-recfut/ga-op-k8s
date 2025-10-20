resource "vault_policy" "oidc_recordedfuture" {
  name = "oidc-recordedfuture"
  policy = <<EOT
path "secret/data/wl/etl/clients/*" {
  capabilities = ["read"]
}
path "secret/metadata" {
  capabilities = ["list"]
}
path "secret/metadata/wl" {
  capabilities = ["list"]
}
path "secret/metadata/wl/etl" {
  capabilities = ["list"]
}
path "secret/metadata/wl/etl/clients/*" {
  capabilities = ["list"]
}
path "secret/metadata/wl/etl/clients/*" {
  capabilities = ["read","list"]
}
EOT
}