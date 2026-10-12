resource "vault_policy" "external_secrets" {
  name   = "external-secrets"
  policy = <<EOT
path "secret/data/goharbor/*" {
  capabilities = ["read"]
}
path "secret/data/apm/*" {
  capabilities = ["read"]
}
path "secret/data/camel-k/*" {
  capabilities = ["read"]
}
path "secret/data/sa/camel-*" {
  capabilities = ["read"]
}
path "secret/data/magescanner/similarweb" {
  capabilities = ["read"]
}
path "secret/data/es-creds-compose-prod/slack-cron-job" {
  capabilities = ["read"]
}
path "secret/data/es-creds-compose-prod/magescanner" {
	capabilities = ["read"]
}
path "secret/data/vortex/*" {
  capabilities = ["read"]
}
path "secret/metadata/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/etl/*" {
  capabilities = ["read"]
}
path "secret/data/mw/charts-syncer/*" {
  capabilities = ["read"]
}
path "secret/data/mw/elastic/mon" {
  capabilities = ["read"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read"]
}
path "secret/data/misc/gitlab/token/read_repo" {
   capabilities = ["read"]
}
path "secret/data/mw/tarantool/*" {
  capabilities = ["read"]
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
