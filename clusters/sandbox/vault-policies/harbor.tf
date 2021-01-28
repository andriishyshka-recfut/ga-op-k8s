resource "vault_policy" "harbor" {
  name = "harbor"

  policy = <<EOT
path "secret/minio/users" {
  capabilities = ["read","list"]
}
EOT
}
