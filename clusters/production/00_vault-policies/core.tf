resource "vault_policy" "core" {
  name = "core"

  policy = <<EOT
path "secret/data/minio/users" {
  capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/*" {
  capabilities = ["read","list"]
}
path "secret/data/captcha" {
  capabilities = ["read","list"]
}
EOT
}
