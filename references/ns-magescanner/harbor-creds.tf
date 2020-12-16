data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "kubernetes_secret" "harbor" {
  metadata {
    name      = "harbor"
    namespace = local.ns
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "harbor.infra.digaweb.com": {
      "username": "${data.vault_generic_secret.harbor_token.data.user}",
      "password": "${data.vault_generic_secret.harbor_token.data.password}"
     }
    }
  }
DOCKER
  }

  type       = "kubernetes.io/dockerconfigjson"
  depends_on = [kubernetes_namespace.ns]
}
