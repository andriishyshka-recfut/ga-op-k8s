resource "vault_policy" "pki" {
  name   = "pki"
  policy = <<EOT
path "pki/issue/*" {
  capabilities = ["create", "update"]
}
path "pki*/issue/*" {
  capabilities = ["create", "update"]
}
path "pki/sign/*" {
  capabilities = ["create", "update"]
}
path "pki*/sign/*" {
  capabilities = ["create", "update"]
}
path "pki/roles/*" {
  capabilities = ["create", "update"]
}
path "pki*/roles/*" {
  capabilities = ["create", "update"]
}
path "pki/revoke" {
  capabilities = ["create", "update"]
}
path "pki*/revoke" {
  capabilities = ["create", "update"]
}
path "pki/tidy" {
  capabilities = ["create", "update"]
}
path "pki*/tidy" {
  capabilities = ["create", "update"]
}
path "pki*" {
	capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
EOT
}
