resource "vault_policy" "pi" {
  name   = "pi"
  policy = <<EOT
path "secret/data/pi/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/*" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
path "secret/data/oidc_google_prod" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/misc/slack/app/MINION" {
   capabilities = ["read","list"]
}
EOT
}
