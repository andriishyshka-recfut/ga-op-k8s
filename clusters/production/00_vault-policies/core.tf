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
path "secret/data/challenger" {
  capabilities = ["read","list"]
}
path "secret/data/pi/*" {
  capabilities = ["read","list"]
}
path "secret/data/geo/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/*" {
  capabilities = ["read","list"]
}
path "secret/data/cppminion/*" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
path "secret/data/slack/auth" {
  capabilities = ["read","list"]
}

EOT
}
