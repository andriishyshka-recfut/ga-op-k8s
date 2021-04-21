resource "vault_policy" "core" {
  name = "core"

  policy = <<EOT
path "secret/minio/users" {
  capabilities = ["read","list"]
}
path "secret/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
path "secret/mongo/*" {
  capabilities = ["read","list"]
}
path "secret/captcha" {
  capabilities = ["read","list"]
}
EOT
}
