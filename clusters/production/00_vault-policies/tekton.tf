resource "vault_policy" "tekton" {
  name = "tekton"

  policy = <<EOT

path "secret/data/*" {
  capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list","create","update"]
}
path "auth/token/create" {
  capabilities=["update"]
}
path "auth/k8s-production-green/role/*" {
  capabilities=["create","update","read","list"]
}
path "auth/k8s-production-blue/role/*" {
  capabilities=["create","update","read","list"]
}
path "sys/auth" {
  capabilities = ["read","list"]
}
EOT
}
