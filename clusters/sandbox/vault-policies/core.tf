resource "vault_policy" "core" {
  name = "core"

  policy = <<EOT
path "secret/minio/users" {
  capabilities = ["read","list"]
}
path "secret/elasticsearch-admin/sandbox" {
  capabilities = ["read","list"]
}
path "secret/mongo/magescanner" {
  capabilities = ["read","list"]
}
EOT
}
