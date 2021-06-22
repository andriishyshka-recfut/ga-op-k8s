
resource "vault_policy" "gitlab" {
  name = "gitlab-dev"

  policy = <<EOT
path "secret/data/goharbor/docker_login" {
  capabilities = ["read","list"]
}
path "secret/data/whitesource" {
  capabilities = ["read","list"]
}
EOT
}
