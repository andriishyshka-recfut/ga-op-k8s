resource "vault_policy" "ai" {
  name = "ai"
  policy = <<EOT
path "secret/data/wl/ai/*" {
    capabilities = ["read","list"]
}
path "secret/metadata/wl/ai/*" {
    capabilities = ["read","list"]
}
EOT
}
