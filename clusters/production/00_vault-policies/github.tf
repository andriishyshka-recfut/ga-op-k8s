resource "vault_policy" "red_github" {
  name   = "red.github"
  policy = <<EOT
path "secret/data/goharbor/*" {
  capabilities = ["read"]
}
path "secret/metadata/goharbor/*" {
  capabilities = ["list"]
}
path "secret/metadata/gitlab/*" {
  capabilities = ["list"]
}
path "secret/data/gitlab/*" {
  capabilities = ["read"]
}
path "secret/data/harbor/*" {
  capabilities = ["read"]
}
path "secret/metadata/harbor/*" {
  capabilities = ["list"]
}
EOT
}