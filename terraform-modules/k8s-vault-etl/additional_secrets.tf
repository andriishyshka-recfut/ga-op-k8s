data "vault_generic_secret" "gitlab_token" {
  path = "secret/gitlab"
}

data "vault_generic_secret" "minio_default_settings" {
  path = "secret/etl/minio"
}

data "vault_generic_secret" "email_creds" {
  path = "secret/etl/mail"
}

data "vault_generic_secret" "slack_creds" {
  path = "secret/etl/slack"
}

data "vault_generic_secret" "gcp_sa_keys" {
  path = "secret/etl/google_credentials"
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


resource "kubernetes_secret" "minio_default_settings" {
  metadata {
    name      = "minio-default-settings"
    namespace = local.namespace
  }

  data = {
    "endpoint" = data.vault_generic_secret.minio_default_settings.data.ENDPOINT
    "minio-bucket"    = data.vault_generic_secret.minio_default_settings.data.MINIO_BUCKET
  }
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

resource "kubernetes_secret" "slack_creds" {
  metadata {
    name      = "slack"
    namespace = local.namespace
  }

  data = {
    "slacktoken" = data.vault_generic_secret.slack_creds.data.token
  }
}

resource "kubernetes_secret" "google_credentials" {
  metadata {
    name      = "google-sa-credentials"
    namespace = local.namespace
  }

  data = {
    "cppfeed" = data.vault_generic_secret.gcp_sa_keys.data.cppfeed
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
