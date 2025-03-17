resource "vault_policy" "spiral" {
  name   = "spiral"
  policy = <<EOT
path "secret/data/spiral/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/spiral" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/metaSpiral" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticHosts" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCa" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/_spiral.ms" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticKey" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/elasticCrt" {
  capabilities = ["read","list"]
}
path "secret/data/wl/chatgpt/*" {
  capabilities = ["read","list","update","delete"]
}
path "secret/metadata/wl/chatgpt*" {
  capabilities = ["read","list","update","delete"]
}
EOT
}
