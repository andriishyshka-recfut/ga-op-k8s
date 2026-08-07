resource "vault_policy" "etl" {
  name   = "etl"
  policy = <<EOT
path "secret/data/wl/etl/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/etl/clients/*" {
  capabilities = ["read","list"]
}
path "secret/metadata/wl/etl/*" {
  capabilities = ["read","list"]
}
path "secret/metadata/wl/etl/clients/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticHosts" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCa" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCrt" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticKey" {
  capabilities = ["read","list"]
}
path "secret/metadata/es-creds-compose-prod/metaCitsale" {
  capabilities = ["read","list"]
}
path "secret/metadata/es-creds-compose-prod/citsale" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaCitsale" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/citsale" {
  capabilities = ["read","list"]
}
path "secret/data/wl/etl/observer/minio/old" {
  capabilities = ["read","list"]
}  
path "secret/data/wl/etl/observer/minio/new" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/etl_etl" {
  capabilities = ["read","list"]
}
EOT
}
