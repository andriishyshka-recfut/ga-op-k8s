resource "vault_policy" "shout" {
  name   = "shout"
  policy = <<EOT
path "secret/data/shout/*" {
  capabilities = ["read","list","update"]
}
path "secret/metadata/shout/clients*" {
  capabilities = ["read","list","update","delete"]
}
path "secret/data/es-creds-compose-prod/shout" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaShout" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
