data "vault_kv_secret_v2" "artifactory_creds" {
  mount = "secret"
  name  = "misc/artifactory/creds"
}

resource "helm_release" "etl_operator" {
  name                 = "etl-operator"
  chart                = "oci://${var.artifactoryRepoDomain}/ga-helm-local/op/etl-operator"
  version              = "0.1.4"
  namespace            = local.namespace
  wait                 = true
  atomic               = true
  recreate_pods        = true
  repository_username  = data.vault_kv_secret_v2.artifactory_creds.data["user"]
  repository_password  = data.vault_kv_secret_v2.artifactory_creds.data["password"]
  repository_cert_file = var.artifactoryRepoDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.crt" : null
  repository_key_file  = var.artifactoryRepoDomain == "repo-external.recfut.com" ? "/tmp/artifactory-client.key" : null
  values               = [templatefile("${path.module}/templates/operator.tftpl", { Values = local.operatorValues })]
}
