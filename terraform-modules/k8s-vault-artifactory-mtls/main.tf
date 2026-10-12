data "vault_kv_secret_v2" "artifactory_certs" {
  mount = "secret"
  name  = "misc/artifactory/certs"
}

resource "local_sensitive_file" "cert" {
  filename        = "/tmp/artifactory-client.crt"
  content         = data.vault_kv_secret_v2.artifactory_certs.data["tls_crt"]
  file_permission = "0600"
}

resource "local_sensitive_file" "key" {
  filename        = "/tmp/artifactory-client.key"
  content         = data.vault_kv_secret_v2.artifactory_certs.data["tls_key"]
  file_permission = "0600"
}
