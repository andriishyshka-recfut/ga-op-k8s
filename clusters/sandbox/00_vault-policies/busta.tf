resource "vault_policy" "busta" {
  name   = "busta"
  policy = <<EOT
path "secret/data/wl/busta/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/clicker/engine-definer" {
  capabilities = ["read","list"]
}
path "secret/data/misc/sa/google/busta" {
  capabilities = ["read","list"]
}
path "secret/data/misc/sa/amazon/busta" {
  capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/elastic7-v2" {
  capabilities = ["read","list"]
}
path "secret/data/wl/soda/prompts" {
  capabilities = ["read","list"]
}
path "secret/data/wl/busta/mark/prompts" {
  capabilities = ["read","list"]
}
path "secret/data/clicker/minio" {
  capabilities = ["read","list"]
}
EOT
}