data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}


resource "kubernetes_secret" "harbor_maid" {
  metadata {
    name      = "harbor"
    namespace = "maid"
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

  type = "kubernetes.io/dockerconfigjson"

}
