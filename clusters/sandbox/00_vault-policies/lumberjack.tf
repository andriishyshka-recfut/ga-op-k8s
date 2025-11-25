resource "vault_policy" "lumberjack" {
  name = "lumberjack"
  policy = <<EOT
path "secret/data/wl/lumberjack/*" {
    capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaLumberjack" {
    capabilities = ["read","list"]
}
path "secret/data/mongo/metaLumberjack" {
    capabilities = ["read","list"]
}
path "secret/data/red/mw/monitoring/otel" {
    capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
EOT
}