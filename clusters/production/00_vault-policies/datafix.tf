resource "vault_policy" "datafix" {
  name   = "datafix"
  policy = <<EOT
path "secret/data/mongo/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/*" {
  capabilities = ["read","list"]
}
path "secret/data/oidc/*" {
  capabilities = ["read","list"]
}
path "secret/data/misc/sa/google/datafix" {
  capabilities = ["read","list"]
}
path "secret/data/wl/datafix/datafix/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/datafix_datafix" {
  capabilities = ["read","list"]
}
path "secret/data/minion-pan-upload/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/postgres/db-users/birl" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/datafix_datafix" {
   capabilities = ["read","list"]
}
EOT
}
