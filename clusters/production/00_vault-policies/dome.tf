resource "vault_policy" "dome" {
  name   = "dome"
  policy = <<EOT
path "secret/data/minio/users" {
  capabilities = ["read","list"]
}
path "secret/data/wl/threads/sheet" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/dome" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/production" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaDome" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaDome" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/threads/google" {
  capabilities = ["read","list"]
}
path "secret/data/wl/threads/sheet" {
  capabilities = ["read","list"]
}
path "secret/data/wl/dome/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/wl/ai/chatgpt/dome-dutyfree" {
   capabilities = ["read","list"]
}
EOT

}
