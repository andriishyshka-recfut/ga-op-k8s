data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}


resource "kubernetes_secret" "harbor_image_pull_secrets" {
  for_each = local.injectHarborImagePullSecrets
  metadata {
    name      = "harbor"
    namespace = each.key
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "harbor.t.regemini.io": {
      "username": "${data.vault_generic_secret.harbor_token.data.user}",
      "password": "${data.vault_generic_secret.harbor_token.data.password}"
     }
    }
  }
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
  depends_on = [
    kubernetes_namespace.ns
  ]

}
