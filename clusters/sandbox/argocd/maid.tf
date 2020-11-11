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

  type       = "kubernetes.io/dockerconfigjson"
  depends_on = [kubernetes_namespace.maid]
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

  data = { "secret-token" = lookup(data.kubernetes_secret.apm-token.data, "secret-token") }

}

data "kubernetes_secret" "gcs-credentials" {
  metadata {
    name      = "gcs-credentials"
    namespace = "monitoring"
  }
}

locals {
  es = yamldecode(file("maid_elastic_settings.yaml"))
  gke_cluster_connection_settings = {
    HOST                   = data.vault_generic_secret.k8s_auth.data.HOST
    API_KEY                = data.vault_generic_secret.k8s_auth.data.k8s_sa_token
    CLUSTER_CA_CERTIFICATE = data.vault_generic_secret.k8s_auth.data.CLUSTER_CA_CERTIFICATE
  }
}
module "maid-elastic" {
  source                          = "../../../terraform-modules/k8s-elasticsearch"
  elastic_settings                = local.es.elastic_settings
  gke_cluster_connection_settings = local.gke_cluster_connection_settings
  backup_sa_private_key           = base64encode(lookup(data.kubernetes_secret.gcs-credentials.data, "gcs.client.default.credentials_file"))
  store_es_password_in_vault      = false
  depends_on                      = [kubernetes_namespace.maid]
}

resource "kubernetes_secret" "minio-credentials2" {
  metadata {
    name      = "minio-credentials"
    namespace = "maid"
  }

  data = {
    "accesskey" = data.vault_generic_secret.minio-credentials.data.accessKey
    "secretkey" = data.vault_generic_secret.minio-credentials.data.secretKey
  }
  depends_on = [kubernetes_namespace.minio]

}
