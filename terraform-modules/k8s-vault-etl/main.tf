data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "helm_release" "etl_operator" {
  name                = "etl-operator"
  chart               = "oci://harbor.regemini.io/helm/etl-operator"
  version             = "0.1.3"
  namespace           = local.namespace
  wait                = true
  atomic              = true
  recreate_pods       = true
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
  values = [templatefile("${path.module}/templates/operator.tftpl",{Values = local.operatorValues})]
}
