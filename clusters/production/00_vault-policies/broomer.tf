resource "vault_policy" "broomer" {
  name   = "broomer"
  policy = <<EOT
path "/secret/data/es-creds-compose-prod/metaBroomer" {
  capabilities = ["read","list"]
}
path "/secret/data/es-creds-compose-prod/elastic*" {
  capabilities = ["read","list"]
}
path "/secret/data/es-creds-compose-prod/_broomer.ms" {
  capabilities = ["read","list"]
}
path "/secret/data/mongo/metaBroomer" {
  capabilities = ["read","list"]
}
path "/secret/data/mw/minio/sa/attachments_broomer" {
  capabilities = ["read","list"]
}
path "/secret/data/wl/broomer/*" {
  capabilities = ["read","list"]
}
EOT
}
