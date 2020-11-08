resource "kubernetes_namespace" "maid" {
  metadata {
    name = "maid"
    # labels = {
    #   istio-injection = "enabled"
    # }
  }
}


data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}



resource "kubernetes_secret" "harbor" {
  metadata {
    name      = "harbor"
    namespace = "maid"
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "harbor.infra.digaweb.com": {
      "auth": "${base64encode("${data.vault_generic_secret.harbor_token.data.user}:${data.vault_generic_secret.harbor_token.data.user}")}"
    }
  }
}
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
  depends_on = [
    kubernetes_namespace.maid
  ]
}
