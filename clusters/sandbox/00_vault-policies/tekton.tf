resource "vault_policy" "tekton" {
  name = "tekton"

  policy = <<EOT

path "sys/mounts/pki-*" {
  capabilities = ["create","update"]
}
path "secret/*" {
  capabilities = ["read","list"]
}
path "secret/data/*" {
  capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list","create","update"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list","create","update"]
}
path "auth/token/create" {
  capabilities=["update"]
}
path "auth/k8s-sandbox-green/role/*" {
  capabilities=["create","update","read","list"]
}
path "auth/k8s-sandbox-blue/role/*" {
  capabilities=["create","update","read","list"]
}
path "sys/auth" {
  capabilities = ["read","list"]
}
path "sys/mounts/auth/k8s-sandbox-*" {
  capabilities = ["create","update","read","list"]
}
path "pki*" {
	capabilities=["create","update","read","list"]
}
path "secret/data/tls-proxy/*" {
	capabilities=["create","update","read","list"]
}

path "secret/data/flux/*" {
  capabilities = ["read","create","update","list"]
}
path "secret/data/logstash/*" {
  capabilities = ["read","create","update","list"]
}
path "secret/data/wl/etl/*" {
  capabilities = ["read","create","update","list"]
}
path "secret/data/misc/tekton/auth-proxy-creds" {
  capabilities = ["read","create","update","list"]
}
path "secret/data/misc/gitlab/token/read_repo" {
  capabilities = ["read","list"]
}
path "postgres/*" {
  capabilities = ["create","update","read","list","delete"]
}
path "postgres-ha/*" {
  capabilities = ["create","update","read","list","delete"]
}
EOT
}
