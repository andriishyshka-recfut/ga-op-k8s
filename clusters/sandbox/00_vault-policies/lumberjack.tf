resource "vault_policy" "lumberjack" {
  name = "lumberjack"
  policy = <<EOT
path "secret/data/wl/lumberjack/*" {
    capabilities = ["read","list"]
}
path "secret/data/logstash/*" {
    capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
