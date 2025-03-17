
data "vault_generic_secret" "minio_default_settings" {
  path = "secret/${var.SecretPath}/minio"
}

data "vault_generic_secret" "gcp_sa_keys" {
  path = "secret/${var.SecretPath}/google_credentials"
}

data "vault_generic_secret" "api_keys" {
  path = "secret/${var.SecretPath}/vault"
}


data "vault_generic_secret" "elastic_ca" {
  path = "${local.elasticCertsPath}/elasticCa${local.elasticSecretsPrefix}"
}

data "vault_generic_secret" "elastic_crt" {
  path = "${local.elasticCertsPath}/elasticCrt${local.elasticSecretsPrefix}"
}

data "vault_generic_secret" "elastic_key" {
  path = "${local.elasticCertsPath}/elasticKey${local.elasticSecretsPrefix}"
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


resource "kubernetes_secret" "api_keys" {
  metadata {
    name      = "api-keys"
    namespace = local.namespace
  }

  data = {
    "vault" = jsonencode(data.vault_generic_secret.api_keys.data)
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


resource "kubernetes_secret" "elastic_certs" {
  metadata {
    name      = "elastic-certs"
    namespace = local.namespace
  }
  data = {
    "ca.crt"  = data.vault_generic_secret.elastic_ca.data.ELASTICSEARCH_CA_CRT
    "tls.crt" = data.vault_generic_secret.elastic_crt.data.ELASTICSEARCH_CLIENT_CRT
    "tls.key" = data.vault_generic_secret.elastic_key.data.ELASTICSEARCH_CLIENT_KEY
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
            "key" = "secret/data/${var.SecretPath}/ssh"
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

resource "kubernetes_manifest" "externalsecret_logstash_creds" {
  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name" = "logstash-creds"
      "namespace" : local.namespace
    }
    "spec" = {
      "target" = {
        "name" = "logstash-creds"
      }
      "dataFrom" = [
        {
          "extract" = {
            "key" = "secret/data/${var.SecretPath}/logstash-creds"
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
