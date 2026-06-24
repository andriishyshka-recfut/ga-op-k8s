data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "helm_release" "thanos" {
  name              = "thanos"
  chart             = "thanos"
#  repository        = "https://charts.bitnami.com/bitnami"
#  repository        = "oci://registry-1.docker.io/bitnamicharts"
#  waiting to resync 
  repository        = "oci://harbor.regemini.io/helm/charts"
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
  wait              = true
  timeout           = 900
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
  version           = local.helmVersion
  take_ownership    = false
  upgrade_install   = false
  values = [
    templatefile("${path.module}/${local.thanosConfigFile}", {
      additional_rule_labels             = var.Cluster,
      thanos_version                     = local.thanosVersion
    })
  ]
}
