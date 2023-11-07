data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "helm_release" "tarantool_operator" {
  name      = "tarantool-operator"
  chart     = "oci://harbor.regemini.io/helm/tarantool-operator"
  wait      = true
  atomic    = true
  namespace = local.namespace
  timeout   = 300
  version   = "1.0.1"
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
}
