resource "vault_policy" "busta" {
  name   = "busta"
  policy = <<EOT
path "secret/data/wl/busta/*" {
  capabilities = ["read","list"]
}
path "secret/metadata/wl/busta/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/clicker/engine-definer" {
  capabilities = ["read","list"]
}
path "secret/data/misc/sa/google/busta" {
  capabilities = ["read","list"]
}
path "secret/data/misc/sa/amazon/busta" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaBusta" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_busta.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
  capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/busta_clicker" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaSoda" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaSoda" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_some.ms" {
  capabilities = ["read","list"]
}
EOT
}

