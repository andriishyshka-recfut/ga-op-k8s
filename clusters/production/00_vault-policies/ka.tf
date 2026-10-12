resource "vault_policy" "ka" {
  name   = "ka"
  policy = <<EOT
path "secret/data/ka/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/ka" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaKa" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/production" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaKa" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticHosts" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCa" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticKey" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCrt" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_ka.ms" {
  capabilities = ["read","list"]
}
path "secret/data/wl/minion/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/wl/ka/*" {
   capabilities = ["read","list"]
}
path "secret/data/misc/slack/app/MINION" {
   capabilities = ["read","list"]
}
EOT
}
