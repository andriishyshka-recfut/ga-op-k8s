resource "vault_policy" "camino" {
  name = "camino"

  policy = <<EOT
path "/secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
path "/secret/data/camino/*" {
  capabilities = ["read","list"]
}
EOT
}
