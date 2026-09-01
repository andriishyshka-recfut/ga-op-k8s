resource "vault_policy" "red_tekton" {
  name   = "red.tekton"
  policy = <<EOT
path "sys/mounts/pki-*" {
  capabilities = ["create","update"]
}
path "sys/mounts/auth/k8s-production-red" {
  capabilities = ["create","update","read","list"]
}
path "secret/data/*" {
  capabilities = ["read","list"]
}
path "secret/data/logstash/*" {
  capabilities = ["create","update","read","list","delete"]
}
path "secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list","create","update"]
}
path "auth/token/create" {
  capabilities=["update"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list","create","update"]
}
path "auth/k8s-production-red/role/*" {
  capabilities=["create","update","read","list"]
}
path "sys/auth" {
  capabilities = ["read","list"]
}
path "pki*" {
	capabilities=["create","update","read","list"]
}
path "secret/data/red/*" {
	capabilities=["create","update","read","list"]
}
path "secret/metadata/red/tls-proxy/*" {
	capabilities=["read","list"]
}
path "secret/metadata/red/ingress/*" {
	capabilities=["read","list"]
}
path "secret/data/wl/etl/logstash-creds" {
	capabilities=["create","update","read","list"]
}
path "secret/data/certificates/*" {
	capabilities=["create","update","read","list"]
}
path "secret/metadata/certificates/*" {
	capabilities=["read","list"]
}
path "secret/data/misc/artifactory/creds" {
  capabilities = ["read"]
}
EOT
}
