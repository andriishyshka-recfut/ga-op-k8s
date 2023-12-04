

data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "kubernetes_secret" "harbor_image_pull_secrets" {
  count = local.installCount
  metadata {
    name      = "camel-k-registry-secret"
    namespace = local.camelNs
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "harbor.regemini.io": {
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
  count = local.installCount
  name       = "camel-k"
  chart      = "camel-k"
  repository = "https://apache.github.io/camel-k/charts"
  namespace  = local.camelNs
  wait       = true
  atomic     = true
  version    = "0.13.0"
  values = [
    file("${path.module}/camel-k-values.yaml")
  ]
  depends_on = [
    kubernetes_secret.harbor_image_pull_secrets
  ]
}

resource "null_resource" "harbor_creds" {
count = local.installCount
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export VAULT_ADDR=${var.VaultAddress}
    kubectl patch --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     --namespace=${local.camelNs}  \
     serviceaccount default -p '{"imagePullSecrets": [{"name": "harbor"}]}'

COMMAND
  }
}
