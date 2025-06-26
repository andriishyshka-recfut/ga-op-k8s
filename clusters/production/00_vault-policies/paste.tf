resource "vault_policy" "paste" {
  name   = "paste"
  policy = <<EOT
path "secret/data/minio/users" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
path "database/creds/*" {
 capabilities = ["read","list"]
}
path "sys/leases/*" {
 capabilities = ["read","list","create","update"]
}
path "auth/token/renew*" {
 capabilities = ["read","list","create","update"]
}
path "secret/data/mongo/*" {
 capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
