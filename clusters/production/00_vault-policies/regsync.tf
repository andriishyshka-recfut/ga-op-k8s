resource "vault_policy" "regsync" {
  name   = "regsync"
  policy = <<EOT
path "secret/data/mw/charts-syncer/*" {
  capabilities = ["read","list"]
}
EOT
}
