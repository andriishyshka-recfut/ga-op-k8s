data "vault_generic_secret" "minio_default_settings" {
  path = "secret/${var.SecretPath}/minio"
}

data "vault_generic_secret" "gcp_sa_keys" {
  path = "secret/${var.SecretPath}/google_credentials"
}

data "vault_generic_secret" "api_keys" {
  path = "secret/${var.SecretPath}/vault"
}

data "vault_generic_secret" "slack" {
  path = "secret/misc/slack/app/Ansible"
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
    "endpoint"     = data.vault_generic_secret.minio_default_settings.data.ENDPOINT
    "minio-bucket" = data.vault_generic_secret.minio_default_settings.data.MINIO_BUCKET
  }
}


resource "kubernetes_secret" "api_keys" {
  metadata {
    name      = "api-keys"
    namespace = local.namespace
  }

  data = {
    "vault" = jsonencode(local.etlVault)
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

resource "kubectl_manifest" "externalsecret_ssh" {
  yaml_body  = templatefile("${path.module}/ext_ssh.tftpl", { namespace = local.namespace, vault_path = var.SecretPath })
  depends_on = [helm_release.etl_operator]
}

resource "kubectl_manifest" "externalsecret_logstash_creds" {
  yaml_body  = templatefile("${path.module}/ext_logstash.tftpl", { namespace = local.namespace, vault_path = var.SecretPath })
  depends_on = [helm_release.etl_operator]
}


