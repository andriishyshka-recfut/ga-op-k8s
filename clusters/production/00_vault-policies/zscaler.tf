resource "vault_policy" "zscaler_vm" {
  name = "zscaler-vm"

  policy = <<EOT
path "secret/data/misc/zscaler/server-keys" {
  capabilities = ["read"]
}
EOT
}
