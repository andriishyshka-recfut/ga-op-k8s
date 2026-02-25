resource "vault_policy" "mule" {
  name = "mule"

  policy = <<EOT
path "secret/data/elasticsearch-admin/elastic7-v2" {
  capabilities = ["read","list"]
}
path "secret/data/wl/mule*" {
  capabilities = ["read","list"]
}
path "/secret/data/misc/cybera/gemini" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/*" {
  capabilities = ["read","list"]
}
EOT
}
