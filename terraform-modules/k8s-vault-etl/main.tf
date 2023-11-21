data "vault_generic_secret" "harbor_token" {
  path = "secret/goharbor/docker_login"
}

resource "helm_release" "etl_operator" {
  name                = "etl-operator"
  chart               = "oci://harbor.regemini.io/helm/etl-operator"
  version             = "0.1.1"
  namespace           = local.namespace
  wait                = true
  atomic              = true
  recreate_pods       = true
  repository_username = data.vault_generic_secret.harbor_token.data.user
  repository_password = data.vault_generic_secret.harbor_token.data.password
  set {
    name  = "image.tag"
    value = "v2.5-rc9"
  }
  set {
    name  = "ansibleGit.tag"
    value = "rc6"
  }
  set {
    name  = "camino.tag"
    value = "v5.0.14"
  }
  set {
    name  = "gs2s3.tag"
    value = "v5.0.1"
  }
  set {
    name  = "vaultPath"
    value = "k8s-${var.Cluster}-${var.Color}"
  }
  set {
    name  = "vaultRole"
    value = local.namespace
  }
  set {
    name  = "monitoredNamespace"
    value = local.namespace
  }
  set {
    name  = "elasticSecretsPath"
    value = local.elasticSecretsPath
  }
  set {
    name  = "resources.requests.cpu"
    value = "200m"
  }
  set {
    name  = "resources.requests.memory"
    value = "512Mi"
  }
  set {
    name  = "resources.limits.cpu"
    value = "400m"
  }
  set {
    name  = "resources.limits.memory"
    value = "1024Mi"
  }
}




resource "kubernetes_manifest" "externalsecret_etl_creds" {
  for_each = local.clients
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name" = "etl-${each.key}"
      "namespace" : local.namespace
    }
    "spec" = {
      "data" = [
        # creates a secret for one entity
        {
          "secretKey" = "etl-settings"
          "remoteRef" = {
            "key"      = "secret/data/etl/clients/${each.key}"
            "property" = ""
          }
        },
        # Creates one mega-secret with entry for each value found
        # {
        #   "find" = {
        #     "path" = "secret/data/etl/clients"
        #     "name" = {
        #       "regexp" = ".*"
        #     }
        #   }
        # },
      ]
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "SecretStore"
        "name" = "vault-backend"
      }
      #   "target" = {
      #     "name" = "etl-settings-${each.key}"
      #   }
    }
  }
  depends_on = [helm_release.etl_operator]

}

