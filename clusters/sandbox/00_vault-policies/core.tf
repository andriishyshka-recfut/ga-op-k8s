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
path "pki/cert/1c-c6-8d-a3-37-93-da-f1-98-f9-e1-5c-fc-11-0e-36-5e-56-b4-7b" {
  capabilities = ["read"]
}
EOT
}
