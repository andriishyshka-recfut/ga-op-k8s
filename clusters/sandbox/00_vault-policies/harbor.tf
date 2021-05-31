resource "vault_policy" "harbor" {
  name = "harbor"

  policy = <<EOT
path "secret/data/minio/users" {
  capabilities = ["read","list"]
}
path "secret/data/minio-credentials" {
  capabilities = ["read","list"]
}
EOT
}
