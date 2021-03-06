
resource "vault_policy" "magescanner" {
  name = "magescanner"

  policy = <<EOT
path "secret/magescanner/*" {
  capabilities = ["read","list"]
}
path "secret/mongo/magescanner" {
  capabilities = ["read","list"]
}
path "secret/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
EOT
}
