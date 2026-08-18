resource "vault_policy" "tekton" {
  name   = "tekton"
  policy = <<EOT
path "sys/mounts/pki-*" {
  capabilities = ["create","update","read","list"]
}
path "secret/data/*" {
  capabilities = ["read","list"]
}
path "secret/metadata/*" {
  capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list","create","update"]
}
path "sys/mounts/auth/k8s-production-blue" {
	capabilities=["create","update","read","list"]
}
path "sys/mounts/auth/k8s-production-green" {
	capabilities=["create","update","read","list"]
}
path "auth/token/create" {
  capabilities=["update"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list","create","update"]
}
path "auth/k8s-production-green/role/*" {
  capabilities=["create","update","read","list"]
}
path "auth/k8s-production-blue/role/*" {
  capabilities=["create","update","read","list"]
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
path "secret/data/tls-proxy/*" {
	capabilities=["create","update","read","list"]
}
path "secret/metadata/tls-proxy/*" {
	capabilities=["read","list"]
}
path "secret/data/wl/etl/logstash-creds" {
	capabilities=["create","update","read","list"]
}
path "secret/data/flux/*" {
  capabilities = ["read","create","update","list"]
}
path "secret/data/mw/monitoring/prometheus/auth-proxy-credentials" {
  capabilities = ["read","list"]
}
path "sys/mounts/auth/k8s-production-green" {
  capabilities = ["create","update","read","list"]
}
path "postgres/*" {
  capabilities = ["create","update","read","list","delete"]
}
path "postgres-ha-prod/*" {
  capabilities = ["create","update","read","list","delete"]
}
path "secret/data/mw/elastic/mon" {
  capabilities = ["create","update","read","list","delete"]
}
path "secret/data/misc/gitlab/token/read_repo" {
  capabilities = ["read","list"]
}
EOT
}
