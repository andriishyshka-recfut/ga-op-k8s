resource "vault_policy" "camino" {
  name   = "camino"
  policy = <<EOT
path "/secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
path "/secret/data/etl/*" {
  capabilities = ["read","list"]
}
path "/secret/data/es-creds-compose-prod/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
