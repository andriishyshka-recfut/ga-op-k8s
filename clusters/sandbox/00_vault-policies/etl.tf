resource "vault_policy" "camino" {
  name = "camino"

  policy = <<EOT
path "secret/data/etl/*" {
  capabilities = ["read","list"]
}
path "secret/data/etl/clients/*" {
  capabilities = ["read","list"]
}
path "secret/data/logstash/logstash-*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
