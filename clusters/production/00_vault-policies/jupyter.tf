resource "vault_policy" "jupyter" {
  name = "jupyter"
  policy = <<EOT
path "secret/data/es-creds-compose-prod/*" {
  capabilities = ["read","list"]
}
path "secret/data/jupyter/*" {
  capabilities = ["read","list"]
}
path "secret/data/red/tls-proxy/certs/recordedfuture-vortex"{
  capabilities = ["read","list"]
}
path "secret/data/red/tls-proxy/basic-auth/recordedfuture-vortex"{
  capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/jupyter_jupyter"{
  capabilities = ["read","list"]
}
EOT
}
