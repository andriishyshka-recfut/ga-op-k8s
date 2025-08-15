resource "vault_policy" "tekton" {
  name = "tekton"

  policy = <<EOT

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
path "secret/data/misc/gitlab/token/read_repo" {
  capabilities = ["read","list"]
}
EOT
}
