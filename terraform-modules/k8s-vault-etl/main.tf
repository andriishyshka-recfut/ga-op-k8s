resource "helm_release" "etl_operator" {
  name          = "etl-operator"
  chart         = "${path.module}/etl-operator"
  namespace     = local.namespace
  wait          = true
  atomic        = true
  recreate_pods = true
  set {
    name  = "image.tag"
    value = "1.11"
  }
  set {
    name  = "ansibleGit.tag"
    value = "v1.5"
  }
  set {
    name  = "camino.tag"
    value = "v5.0.5"
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


data "vault_generic_secret" "gitlab_token" {
  path = "secret/gitlab"
}

resource "kubernetes_secret" "gitlab_token" {
  metadata {
    name      = "gitlab-creds"
    namespace = local.namespace
  }

  data = {
    "username" = data.vault_generic_secret.gitlab_token.data.username
    "token"    = data.vault_generic_secret.gitlab_token.data.token_read_repo
  }
}


data "vault_generic_secret" "email_creds" {
  path = "secret/etl/mail"
}

resource "kubernetes_secret" "email_creds" {
  metadata {
    name      = "email-creds"
    namespace = local.namespace
  }

  data = {
    "credentials" = data.vault_generic_secret.email_creds.data.credentials
    "pass"        = data.vault_generic_secret.email_creds.data.pass
  }
}

data "vault_generic_secret" "slack_creds" {
  path = "secret/etl/slack"
}

resource "kubernetes_secret" "slack_creds" {
  metadata {
    name      = "slack"
    namespace = local.namespace
  }

  data = {
    "slacktoken" = data.vault_generic_secret.slack_creds.data.token
  }
}


resource "kubernetes_manifest" "externalsecret_ssh" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name" = "ssh"
      "namespace" : local.namespace
    }
    "spec" = {
      "target" = {
        "name" = "ssh"
      }
      "dataFrom" = [
        {
          "extract" = {
            "key" = "secret/data/etl/ssh"
          }
        },
      ]
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "SecretStore"
        "name" = "vault-backend"
      }
    }
  }
  depends_on = [helm_release.etl_operator]

}
