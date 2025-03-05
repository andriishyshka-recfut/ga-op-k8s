resource "vault_policy" "gs2es" {
  name   = "gs2es"
  policy = <<EOT
path "secret/data/gs2es/*" {
  capabilities = ["read","list"]
}
path "/secret/data/wl/aws2kafka-check/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/gs2es" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaGs2esCppMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_gs2es-cpp.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaGs2datafixMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_gs2datafix.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticHosts" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCa" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_gs2es-cpp.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticKey" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCrt" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaGs2esCheckerMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/checker" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaGs2esFraudfinderMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_gs2es-fraudfinder.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaEs2gsMagecart-similarwebMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_similarweb.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaEs2mysql-roicalcMs" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/roi" {
  capabilities = ["read","list"]
}
path "secret/data/wl/clicker/engine-definer" {
  capabilities = ["read","list"]
}
EOT
}
