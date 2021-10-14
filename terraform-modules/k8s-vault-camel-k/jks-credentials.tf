data "vault_generic_secret" "es_credentials" {
  path = "secret/camel-k/elasticsearch"
}


data "external" "generate_jks" {
  program = ["bash", "${path.module}/data-jks.sh"]
  query = {
    clientKey = data.vault_generic_secret.es_credentials.data.ELASTICSEARCH_CLIENT_KEY
    clientCrt = data.vault_generic_secret.es_credentials.data.ELASTICSEARCH_CLIENT_CRT
    caCrt = data.vault_generic_secret.es_credentials.data.ELASTICSEARCH_CA_CRT
    keystorePass = data.vault_generic_secret.es_credentials.data.KEYSTORE_PASSWORD
  }
}


resource "kubernetes_secret" "es_credentials" {
  metadata {
    name = "jks"
    namespace = local.camelNs
  }
  data = {
    username = data.vault_generic_secret.es_credentials.data.USERNAME
    password = data.vault_generic_secret.es_credentials.data.PASSWORD
    keystorePass = data.vault_generic_secret.es_credentials.data.KEYSTORE_PASSWORD
  }
  binary_data = {
    keystore = data.external.generate_jks.result.keystore
  }

}


data "vault_generic_secret" "mysql_credentials" {
  path = "secret/camel-k/mysql"
}

resource "kubernetes_secret" "mysql_credentials" {
  metadata {
    name = "mysql"
    namespace = local.camelNs
  }
  data = {
    MYSQL_USER = data.vault_generic_secret.mysql_credentials.data.MYSQL_USER
    MYSQL_PASSWORD = data.vault_generic_secret.mysql_credentials.data.MYSQL_PASSWORD
    WP_URL = data.vault_generic_secret.mysql_credentials.data.WP_URL
  }

}
