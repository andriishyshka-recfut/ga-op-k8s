resource "vault_policy" "tekton" {
  name = "tekton"

  policy = <<EOT

path "secret/data/*" {
  capabilities = ["read","list"]
}
path "auth/token/create" {
  capabilities=["update"]
}

EOT
}
