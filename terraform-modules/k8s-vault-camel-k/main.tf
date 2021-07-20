

data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "kubernetes_secret" "harbor_image_pull_secrets" {

  metadata {
    name      = "camel-k-registry-secret"
    namespace =  "camel-k"
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
  ]

}

resource "helm_release" "kamel" {
  name   = "camel-k"
  chart = "camel-k"
  repository  = "https://apache.github.io/camel-k/charts"
  namespace = "camel-k"
  wait   = true
  atomic = true
  version = "0.6.0"
  values = [
    file("${path.module}/camel-k-values.yaml")
  ]
  depends_on = [
    kubernetes_secret.harbor_image_pull_secrets
  ]
}
