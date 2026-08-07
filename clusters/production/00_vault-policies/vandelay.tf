resource "vault_policy" "vandelay" {
  name   = "vandelay"
  policy = <<EOT
path "secret/data/wl/vandelay/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/vandelay/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_vandelay.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaVandelay" {
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
path "secret/data/misc/oidc/vault_token" {
	capabilities = ["read","list"]
}
path "secret/data/oidc_google_prod" {
	capabilities = ["read","list"]
}
path "auth/k8s-production-red/login" {
  capabilities=["create","update","read","list"]
}
path "secret/data/mongo/metaVandelay" {
  capabilities=["read","list"]
}
path "secret/data/red/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/main_vandelay" {
   capabilities = ["read","list"]
}
EOT
}
