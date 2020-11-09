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
      "username": "${data.vault_generic_secret.harbor_token.data.maid_account_name}",
      "password": "${data.vault_generic_secret.harbor_token.data.maid_account_token}"
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

data "kubernetes_secret" "apm-token" {
  metadata {
    name      = "apm-monitoring-apm-token"
    namespace = "monitoring"
  }
}

resource "kubernetes_secret" "apm-token" {
  metadata {
    name      = "apm-token"
    namespace = "maid"
  }

  data = {
    "secret-token" = lookup(data.kubernetes_secret.apm-token.data, "secret-token")
  }

}
