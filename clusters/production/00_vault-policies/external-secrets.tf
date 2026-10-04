resource "vault_policy" "external_secrets" {
  name   = "external-secrets"
  policy = <<EOT
path "secret/data/goharbor/*" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
path "secret/data/camel-k/*" {
  capabilities = ["read","list"]
}
path "secret/data/sa/camel-*" {
  capabilities = ["read","list"]
}
path "secret/data/magescanner/similarweb" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/slack-cron-job" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/magescanner" {
	capabilities = ["read","list"]
}
path "secret/data/vortex/*" {
  capabilities = ["read","list"]
}
path "secret/metadata/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/etl/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/charts-syncer/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/elastic/mon" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/misc/gitlab/token/read_repo" {
   capabilities = ["read","list"]
}
path "secret/data/red/mw/logstash/*" {
   capabilities = ["read","list"]
}
path "secret/data/wl/reports/minio"{
   capabilities = ["read","list"]
}
path "secret/data/misc/github/app/recfut-gemini-fluxcd" {
  capabilities = ["read"]
}
path "secret/data/misc/artifactory/creds" {
  capabilities = ["read"]
}
path "secret/data/misc/artifactory/certs" {
  capabilities = ["read"]
}
EOT
}
