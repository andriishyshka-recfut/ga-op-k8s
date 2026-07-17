data "vault_pki_secret_backend_issuer" "elastic_ca" {
  backend    = "/pki-elastic-int"
  issuer_ref = "default"
}
resource "kubernetes_secret" "metricbeat_elastic_ca" {
  for_each = var.metricbeats_setttings

  metadata {
    name      = "${lookup(each.value, "name", each.key)}-elastic-ca"
    namespace = var.ElasticSettings.globalSettings.namespace
  }

  data = {
    "ca.crt" = data.vault_pki_secret_backend_issuer.elastic_ca.certificate
  }
}

resource "kubernetes_secret" "auditbeat_elastic_ca" {
  for_each = var.auditbeats_setttings

  metadata {
    name      = "${lookup(each.value, "name", each.key)}-elastic-ca"
    namespace = var.ElasticSettings.globalSettings.namespace
  }

  data = {
    "ca.crt" = data.vault_pki_secret_backend_issuer.elastic_ca.certificate
  }
}


resource "kubernetes_secret" "filebeat_elastic_ca" {
  for_each = local.filebeats_with_vault_ca

  metadata {
    name      = "${each.value.name}-elastic-ca"
    namespace = each.value.namespace
  }

  data = {
    "ca.crt" = data.vault_pki_secret_backend_issuer.elastic_ca.certificate
  }

  depends_on = [
    data.vault_pki_secret_backend_issuer.elastic_ca
  ]
}
