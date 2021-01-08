


resource "helm_release" "kafka_operator" {
  name       = "kafka-operator"
  chart      = "strimzi-kafka-operator"
  repository = "https://strimzi.io/charts/"
  wait       = true
  atomic     = true
  namespace  = local.kafkaNs
  # version    = "v1.4.3"
  timeout = 900
}


data "vault_generic_secret" "root_credentials_from_vault" {
  path = local.vaultPathForMinioRootCredentials
}

resource "kubernetes_secret" "minio_credentials_kubernetes_secret" {
  metadata {
    name      = "minio-credentials"
    namespace = local.kafkaNs
  }

  data = {
    "properties" = <<EOF
    accesskey = ${data.vault_generic_secret.root_credentials_from_vault.data.accessKey}
    secretkey = ${data.vault_generic_secret.root_credentials_from_vault.data.secretKey}
EOF
    "accesskey"  = data.vault_generic_secret.root_credentials_from_vault.data.accessKey
    "secretkey"  = data.vault_generic_secret.root_credentials_from_vault.data.secretKey
  }

}

data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "kubernetes_secret" "harbor_login_creds" {
  metadata {
    name      = "harbor"
    namespace = local.kafkaNs
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

resource "helm_release" "kafka_cluster" {
  name      = "kafka-cluster"
  chart     = "${path.module}/kafka"
  namespace = local.kafkaNs
  wait      = true
  atomic    = true
  depends_on = [
    helm_release.kafka_operator,
    kubernetes_secret.minio_credentials_kubernetes_secret,
    kubernetes_secret.harbor_login_creds
  ]
}
