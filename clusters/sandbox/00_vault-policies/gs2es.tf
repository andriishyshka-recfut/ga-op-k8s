resource "vault_policy" "gs2es" {
  name = "gs2es"

  policy = <<EOT
path "secret/data/gs2es/*" {
  capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/wl/clicker/engine-definer" {
  capabilities = ["read","list"]
}
path "secret/data/misc/slack/app/SANDBOX" {
   capabilities = ["read","list"]
}
EOT
}