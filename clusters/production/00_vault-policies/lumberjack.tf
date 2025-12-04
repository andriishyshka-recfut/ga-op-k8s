resource "vault_policy" "lumberjack" {
  name = "lumberjack"
  policy = <<EOT
path "secret/data/red/wl/lumberjack/*" {
    capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaLumberjack" {
    capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_lumberjack.ms" {
    capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "secret/data/logstash/*" {
    capabilities = ["read","list"]
}
path "secret/data/mongo/metaLumberjack" {
    capabilities = ["read","list"]
}
path "secret/data/red/mw/monitoring/otel" {
    capabilities = ["read","list"]
}
EOT
}