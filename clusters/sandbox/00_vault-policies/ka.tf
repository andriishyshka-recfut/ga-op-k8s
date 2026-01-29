resource "vault_policy" "ka" {
  name = "ka"

  policy = <<EOT
path "secret/data/ka/*" {
  capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/*" {
  capabilities = ["read","list"]
}
path "pki/cert/1c-c6-8d-a3-37-93-da-f1-98-f9-e1-5c-fc-11-0e-36-5e-56-b4-7b" {
  capabilities = ["read"]
}
path "database/creds/*" {
  capabilities = ["read","list"]
}
path "sys/leases/renew" {
  capabilities = ["read","list","create","update"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/misc/slack/app/SANDBOX" {
   capabilities = ["read","list"]
}
EOT
}
