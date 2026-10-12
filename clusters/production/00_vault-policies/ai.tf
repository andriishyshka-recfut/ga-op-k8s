resource "vault_policy" "ai" {
  name = "ai"
  policy = <<EOT
path "secret/data/wl/ai/*" {
    capabilities = ["read","list"]
}
path "secret/metadata/wl/ai/*" {
    capabilities = ["read","list"]
}
path "secret/data/wl/chatgpt/*" {
    capabilities = ["read","list"]
}
path "secret/metadata/wl/chatgpt/*" {
    capabilities = ["read","list"]
}
path "secret/data/wl/grok.ai/*" {
	capabilities = ["read","list"]
}
path "secret/metadata/wl/grok.ai/*" {
	capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
EOT
}
