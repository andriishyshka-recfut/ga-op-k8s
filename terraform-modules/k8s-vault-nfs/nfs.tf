data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "helm_release" "nfs" {
  name                = "nfs"
  namespace           = local.namespace
  chart               = "oci://harbor.regemini.io/helm/nfs"
  wait                = true
  atomic              = true
  version             = "1.0.0"
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
  set = [
    {
      name  = "diskzone"
      value = "us-east4-a"
    },
    {
      name = "diskname"
      value = "nfs-pv-0"
    }
  ]
}
