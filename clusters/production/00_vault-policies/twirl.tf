resource "vault_policy" "twirl" {
  name   = "twirl"
  policy = <<EOT
path "secret/data/twirl/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/twirl" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaTwirl" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticHosts" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCa" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_twirl.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticKey" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCrt" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaEs2gs-twirlMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_twirlRO.ms" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/metaGs2es" {
  capabilities = ["read","list"]
}
path "secret/data/gs2es/es2gs-twirl" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/mongo/metaTwirl" {
   capabilities = ["read","list"]
}
EOT
}
