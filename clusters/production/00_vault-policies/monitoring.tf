resource "vault_policy" "monitoring" {
  name   = "monitoring"
  policy = <<EOT
path "secret/data/elasticsearch-admin/monitoring" {
  capabilities = ["read","list"]
}
EOT
}
